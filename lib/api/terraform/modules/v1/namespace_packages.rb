# frozen_string_literal: true

module API
  module Terraform
    module Modules
      module V1
        class NamespacePackages < ::API::Base
          include ::API::Helpers::Authentication
          helpers ::API::Helpers::PackagesHelpers
          helpers ::API::Helpers::Packages::BasicAuthHelpers

          SEMVER_REGEX = Gitlab::Regex.semver_regex

          TERRAFORM_MODULE_REQUIREMENTS = {
            module_namespace: API::NO_SLASH_URL_PART_REGEX,
            module_name: API::NO_SLASH_URL_PART_REGEX,
            module_system: API::NO_SLASH_URL_PART_REGEX
          }.freeze

          TERRAFORM_MODULE_VERSION_REQUIREMENTS = {
            module_version: SEMVER_REGEX
          }.freeze

          feature_category :package_registry
          urgency :low

          after_validation do
            require_packages_enabled!
          end

          helpers do
            include ::Gitlab::Utils::StrongMemoize

            params :module_name do
              requires :module_name, type: String, desc: '', regexp: API::NO_SLASH_URL_PART_REGEX
              requires :module_system, type: String, regexp: API::NO_SLASH_URL_PART_REGEX
            end

            params :module_version do
              requires :module_version, type: String, desc: 'Module version', regexp: SEMVER_REGEX
            end

            def module_namespace
              find_namespace(params[:module_namespace])
            end
            strong_memoize_attr :module_namespace

            def finder_params
              {
                package_type: :terraform_module,
                package_name: "#{params[:module_name]}/#{params[:module_system]}",
                exact_name: true
              }.tap do |finder_params|
                finder_params[:package_version] = params[:module_version] if params.has_key?(:module_version)
                finder_params[:within_public_package_registry] = true
              end
            end

            def packages
              ::Packages::GroupPackagesFinder.new(
                current_user,
                module_namespace,
                finder_params
              ).execute
            end
            strong_memoize_attr :packages

            def package
              packages.first
            end
            strong_memoize_attr :package

            def package_file
              package.installable_package_files.first
            end
            strong_memoize_attr :package_file
          end

          params do
            requires :module_namespace, type: String, desc: "Group's ID or slug", regexp: API::NO_SLASH_URL_PART_REGEX
            includes :module_name
          end

          namespace 'packages/terraform/modules/v1/:module_namespace/:module_name/:module_system',
            requirements: TERRAFORM_MODULE_REQUIREMENTS do
            authenticate_with do |accept|
              accept.token_types(:personal_access_token, :deploy_token, :job_token)
                    .sent_through(:http_bearer_token)
            end

            after_validation do
              authorize_read_package!(package || module_namespace)
            end

            desc 'List versions for a module' do
              detail 'List versions for a module'
              success code: 200, model: Entities::Terraform::ModuleVersions
              failure [
                { code: 403, message: 'Forbidden' }
              ]
              is_array true
              tags %w[terraform_registry]
            end
            get 'versions' do
              presenter = ::Terraform::ModulesPresenter.new(packages, params[:module_system])
              present presenter, with: ::API::Entities::Terraform::ModuleVersions
            end

            desc 'Get download location for the latest version of a module' do
              detail 'Download the latest version of a module'
              success code: 302
              failure [
                { code: 403, message: 'Forbidden' },
                { code: 404, message: 'Not found' }
              ]
              tags %w[terraform_registry]
            end
            get 'download' do
              latest_version = packages.order_version.last&.version

              if latest_version.nil?
                render_api_error!({ error: "No version found for #{params[:module_name]} module" }, :not_found)
              end

              download_path = api_v4_packages_terraform_modules_v1_module_version_download_path(
                {
                  module_namespace: params[:module_namespace],
                  module_name: params[:module_name],
                  module_system: params[:module_system],
                  module_version: latest_version
                },
                true
              )

              redirect(download_path)
            end

            desc 'Get details about the latest version of a module' do
              detail 'Get details about the latest version of a module'
              success code: 200, model: Entities::Terraform::ModuleVersion
              failure [
                { code: 403, message: 'Forbidden' },
                { code: 404, message: 'Not found' }
              ]
              tags %w[terraform_registry]
            end
            get do
              latest_package = packages.order_version.last

              if latest_package&.version.nil?
                render_api_error!({ error: "No version found for #{params[:module_name]} module" }, :not_found)
              end

              presenter = ::Terraform::ModuleVersionPresenter.new(latest_package, params[:module_system])
              present presenter, with: ::API::Entities::Terraform::ModuleVersion
            end

            params do
              includes :module_version
            end

            namespace '*module_version', requirements: TERRAFORM_MODULE_VERSION_REQUIREMENTS do
              after_validation do
                not_found! unless package && package_file
              end

              desc 'Get download location for specific version of a module' do
                detail 'Download specific version of a module'
                success code: 204
                failure [
                  { code: 403, message: 'Forbidden' },
                  { code: 404, message: 'Not found' }
                ]
                tags %w[terraform_registry]
              end
              get 'download' do
                module_file_path = api_v4_packages_terraform_modules_v1_module_version_file_path(
                  module_namespace: params[:module_namespace],
                  module_name: params[:module_name],
                  module_system: params[:module_system],
                  module_version: params[:module_version]
                )

                if token_from_namespace_inheritable
                  jwt_token = Gitlab::TerraformRegistryToken.from_token(token_from_namespace_inheritable).encoded
                end

                header 'X-Terraform-Get',
                  module_file_path.sub(
                    %r{module_version/file$},
                    "#{params[:module_version]}/file?token=#{jwt_token}&archive=tgz"
                  )
                status :no_content
              end

              namespace 'file' do
                authenticate_with do |accept|
                  accept.token_types(:deploy_token_from_jwt, :job_token_from_jwt, :personal_access_token_from_jwt)
                        .sent_through(:token_param)
                end

                desc 'Download specific version of a module' do
                  detail 'Download specific version of a module'
                  success File
                  failure [
                    { code: 403, message: 'Forbidden' },
                    { code: 404, message: 'Not found' }
                  ]
                  tags %w[terraform_registry]
                end
                get do
                  track_package_event(
                    'pull_package',
                    :terraform_module,
                    project: package.project,
                    namespace: module_namespace
                  )

                  present_package_file!(package_file)
                end
              end

              # This endpoint has to be the last within namespace '*module_version' block
              # due to how the route matching works in grape
              # format: false is required, otherwise grape splits the semver version into 2 params:
              # params[:module_version] and params[:format],
              # thus leading to an invalid/not found module version
              desc 'Get details about specific version of a module' do
                detail 'Get details about specific version of a module'
                success code: 200, model: Entities::Terraform::ModuleVersion
                failure [
                  { code: 403, message: 'Forbidden' },
                  { code: 404, message: 'Not found' }
                ]
                tags %w[terraform_registry]
              end
              get format: false do
                presenter = ::Terraform::ModuleVersionPresenter.new(package, params[:module_system])
                present presenter, with: ::API::Entities::Terraform::ModuleVersion
              end
            end
          end
        end
      end
    end
  end
end
