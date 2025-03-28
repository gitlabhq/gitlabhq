# frozen_string_literal: true

module API
  module Terraform
    module Modules
      module V1
        class ProjectPackages < ::API::Base
          include ::API::Helpers::Authentication
          helpers ::API::Helpers::PackagesHelpers
          helpers ::API::Helpers::Packages::BasicAuthHelpers

          feature_category :package_registry
          urgency :low

          after_validation do
            require_packages_enabled!
          end

          helpers do
            params :terraform_get do
              optional 'terraform-get', type: String, values: %w[1], desc: 'Terraform get redirection flag'
            end

            def present_package_file
              authorize_read_package!(authorized_user_project)

              if declared_params[:'terraform-get'] == '1'
                header 'X-Terraform-Get', "#{request.url.split('?').first}?archive=tgz"
                return no_content!
              end

              package = ::Packages::TerraformModule::PackagesFinder
                .new(authorized_user_project, finder_params)
                .execute
                .first

              not_found! unless package

              track_package_event('pull_package', :terraform_module, project: authorized_user_project,
                namespace: authorized_user_project.namespace)

              present_package_file!(package.installable_package_files.first)
            end

            def finder_params
              { package_name: package_name }.tap do |finder_params|
                finder_params[:package_version] = params[:module_version] if params.key?(:module_version)
              end
            end

            def package_name
              "#{params[:module_name]}/#{params[:module_system]}"
            end

            def authorize_workhorse_params
              {
                subject: authorized_user_project,
                maximum_size: authorized_user_project.actual_limits.terraform_module_max_file_size,
                use_final_store_path: true
              }
            end
          end

          params do
            requires :id, types: [String, Integer], allow_blank: false, desc: 'The ID or full path of a project'
            with(type: String, allow_blank: false, regexp: API::NO_SLASH_URL_PART_REGEX) do
              requires :module_name, desc: 'Module name', documentation: { example: 'infra-registry' }
              requires :module_system, desc: 'Module system', documentation: { example: 'aws' }
            end
          end

          resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
            namespace ':id/packages/terraform/modules/:module_name/:module_system' do
              authenticate_with do |accept|
                accept.token_types(
                  :personal_access_token_with_username,
                  :deploy_token_with_username,
                  :job_token_with_username
                ).sent_through(:http_basic_auth)
              end

              desc 'Download the latest version of a module' do
                detail 'This feature was introduced in GitLab 16.7'
                success code: 204
                failure [
                  { code: 401, message: 'Unauthorized' },
                  { code: 403, message: 'Forbidden' },
                  { code: 404, message: 'Not found' }
                ]
                tags %w[terraform_registry]
              end
              params do
                use :terraform_get
              end
              get do
                present_package_file
              end

              params do
                requires :module_version, type: String, allow_blank: false, desc: 'Module version',
                  regexp: Gitlab::Regex.semver_regex
              end
              namespace '*module_version' do
                desc 'Download a specific version of a module' do
                  detail 'This feature was introduced in GitLab 16.7'
                  success code: 204
                  failure [
                    { code: 401, message: 'Unauthorized' },
                    { code: 403, message: 'Forbidden' },
                    { code: 404, message: 'Not found' }
                  ]
                  tags %w[terraform_registry]
                end
                params do
                  use :terraform_get
                end
                get format: false do
                  present_package_file
                end

                namespace :file do
                  authenticate_with do |accept|
                    accept.token_types(:deploy_token).sent_through(:http_deploy_token_header)
                    accept.token_types(:job_token).sent_through(:http_job_token_header)
                    accept.token_types(:personal_access_token).sent_through(:http_private_token_header)
                  end

                  desc 'Workhorse authorize Terraform Module package file' do
                    detail 'This feature was introduced in GitLab 13.11'
                    success code: 200
                    failure [
                      { code: 403, message: 'Forbidden' }
                    ]
                    tags %w[terraform_registry]
                  end

                  put :authorize do
                    authorize_workhorse!(**authorize_workhorse_params)
                  end

                  desc 'Upload Terraform Module package file' do
                    detail 'This feature was introduced in GitLab 13.11'
                    success code: 201
                    failure [
                      { code: 400, message: 'Invalid file' },
                      { code: 401, message: 'Unauthorized' },
                      { code: 403, message: 'Forbidden' },
                      { code: 404, message: 'Not found' }
                    ]
                    consumes %w[multipart/form-data]
                    tags %w[terraform_registry]
                  end

                  params do
                    requires :file, type: ::API::Validations::Types::WorkhorseFile,
                      desc: 'The package file to be published (generated by Multipart middleware)',
                      documentation: { type: 'file' }
                  end

                  put do
                    authorize_upload!(authorized_user_project)

                    bad_request!('File is too large') if authorized_user_project.actual_limits.exceeded?(
                      :terraform_module_max_file_size, params[:file].size
                    )

                    create_package_file_params = {
                      module_name: params['module_name'],
                      module_system: params['module_system'],
                      module_version: params['module_version'],
                      file: params['file'],
                      build: current_authenticated_job
                    }

                    result = ::Packages::TerraformModule::CreatePackageService
                      .new(authorized_user_project, current_user, create_package_file_params)
                      .execute

                    render_api_error!(result.message, result.reason) if result.error?

                    track_package_event('push_package', :terraform_module, project: authorized_user_project,
                      namespace: authorized_user_project.namespace)

                    created!
                  rescue ObjectStorage::RemoteStoreError => e
                    Gitlab::ErrorTracking.track_exception(e,
                      extra: { file_name: params[:file_name], project_id: authorized_user_project.id })

                    forbidden!
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
