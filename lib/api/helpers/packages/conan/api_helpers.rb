# frozen_string_literal: true

module API
  module Helpers
    module Packages
      module Conan
        module ApiHelpers
          include Gitlab::Utils::StrongMemoize

          def present_download_urls(entity)
            authorize!(:read_package, project)

            presenter = ::Packages::Conan::PackagePresenter.new(
              package,
              current_user,
              project,
              conan_package_reference: params[:conan_package_reference],
              id: params[:id]
            )

            render_api_error!("No recipe manifest found", 404) if yield(presenter).empty?

            present presenter, with: entity
          end

          def present_package_download_urls
            present_download_urls(::API::Entities::ConanPackage::ConanPackageManifest, &:package_urls)
          end

          def present_recipe_download_urls
            present_download_urls(::API::Entities::ConanPackage::ConanRecipeManifest, &:recipe_urls)
          end

          def recipe_upload_urls
            { upload_urls: file_names.select(&method(:recipe_file?)).to_h do |file_name|
                             [file_name, build_recipe_file_upload_url(file_name)]
                           end }
          end

          def package_upload_urls
            { upload_urls: file_names.select(&method(:package_file?)).to_h do |file_name|
                             [file_name, build_package_file_upload_url(file_name)]
                           end }
          end

          def recipe_file?(file_name)
            file_name.in?(::Packages::Conan::FileMetadatum::RECIPE_FILES)
          end

          def package_file?(file_name)
            file_name.in?(::Packages::Conan::FileMetadatum::PACKAGE_FILES)
          end

          def build_package_file_upload_url(file_name)
            options = url_options(file_name).merge(
              conan_package_reference: params[:conan_package_reference],
              package_revision: ::Packages::Conan::FileMetadatum::DEFAULT_PACKAGE_REVISION
            )

            package_file_url(options)
          end

          def build_recipe_file_upload_url(file_name)
            recipe_file_url(url_options(file_name))
          end

          def url_options(file_name)
            {
              package_name: params[:package_name],
              package_version: params[:package_version],
              package_username: params[:package_username],
              package_channel: params[:package_channel],
              file_name: file_name,
              recipe_revision: ::Packages::Conan::FileMetadatum::DEFAULT_RECIPE_REVISION
            }
          end

          def package_file_url(options)
            case package_scope
            when :project
              expose_url(
                api_v4_projects_packages_conan_v1_files_package_path(
                  options.merge(id: project.id)
                )
              )
            when :instance
              expose_url(
                api_v4_packages_conan_v1_files_package_path(options)
              )
            end
          end

          def recipe_file_url(options)
            case package_scope
            when :project
              expose_url(
                api_v4_projects_packages_conan_v1_files_export_path(
                  options.merge(id: project.id)
                )
              )
            when :instance
              expose_url(
                api_v4_packages_conan_v1_files_export_path(options)
              )
            end
          end

          def recipe
            "%{package_name}/%{package_version}@%{package_username}/%{package_channel}" % params.symbolize_keys
          end

          def project
            strong_memoize(:project) do
              case package_scope
              when :project
                find_project!(params[:id])
              when :instance
                full_path = ::Packages::Conan::Metadatum.full_path_from(package_username: params[:package_username])
                find_project!(full_path)
              end
            end
          end

          def package
            strong_memoize(:package) do
              project.packages
                .conan
                .with_name(params[:package_name])
                .with_version(params[:package_version])
                .with_conan_username(params[:package_username])
                .with_conan_channel(params[:package_channel])
                .order_created
                .last
            end
          end

          def token
            strong_memoize(:token) do
              token = nil
              token = ::Gitlab::ConanToken.from_personal_access_token(access_token) if access_token
              token = ::Gitlab::ConanToken.from_deploy_token(deploy_token_from_request) if deploy_token_from_request
              token = ::Gitlab::ConanToken.from_job(find_job_from_token) if find_job_from_token
              token
            end
          end

          def download_package_file(file_type)
            authorize!(:read_package, project)

            package_file = ::Packages::Conan::PackageFileFinder
              .new(
                package,
                params[:file_name].to_s,
                conan_file_type: file_type,
                conan_package_reference: params[:conan_package_reference]
              ).execute!

            track_package_event('pull_package', :conan, category: 'API::ConanPackages', user: current_user, project: project, namespace: project.namespace) if params[:file_name] == ::Packages::Conan::FileMetadatum::PACKAGE_BINARY

            present_carrierwave_file!(package_file.file)
          end

          def find_or_create_package
            package || ::Packages::Conan::CreatePackageService.new(
              project,
              current_user,
              params.merge(build: current_authenticated_job)
            ).execute
          end

          def track_push_package_event
            if params[:file_name] == ::Packages::Conan::FileMetadatum::PACKAGE_BINARY && params[:file].size > 0 # rubocop: disable Style/ZeroLengthPredicate
              track_package_event('push_package', :conan, category: 'API::ConanPackages', user: current_user, project: project, namespace: project.namespace)
            end
          end

          def file_names
            json_payload = Gitlab::Json.parse(request.body.read)

            bad_request!(nil) unless json_payload.is_a?(Hash)

            json_payload.keys
          end

          def create_package_file_with_type(file_type, current_package)
            unless params[:file].size == 0 # rubocop: disable Style/ZeroLengthPredicate
              # conan sends two upload requests, the first has no file, so we skip record creation if file.size == 0
              ::Packages::Conan::CreatePackageFileService.new(
                current_package,
                params[:file],
                params.merge(conan_file_type: file_type, build: current_authenticated_job)
              ).execute
            end
          end

          def upload_package_file(file_type)
            authorize_upload!(project)
            bad_request!('File is too large') if project.actual_limits.exceeded?(:conan_max_file_size, params['file.size'].to_i)

            current_package = find_or_create_package

            track_push_package_event

            create_package_file_with_type(file_type, current_package)
          rescue ObjectStorage::RemoteStoreError => e
            Gitlab::ErrorTracking.track_exception(e, file_name: params[:file_name], project_id: project.id)

            forbidden!
          end

          def find_personal_access_token
            find_personal_access_token_from_conan_jwt ||
              find_personal_access_token_from_http_basic_auth
          end

          def find_user_from_job_token
            return unless route_authentication_setting[:job_token_allowed]

            job = find_job_from_token || return
            @current_authenticated_job = job # rubocop:disable Gitlab/ModuleWithInstanceVariables

            job.user
          end

          def deploy_token_from_request
            find_deploy_token_from_conan_jwt || find_deploy_token_from_http_basic_auth
          end

          def find_job_from_token
            find_job_from_conan_jwt || find_job_from_http_basic_auth
          end

          # We need to override this one because it
          # looks into Bearer authorization header
          def find_oauth_access_token
          end

          def find_personal_access_token_from_conan_jwt
            token = decode_oauth_token_from_jwt

            return unless token

            PersonalAccessToken.find_by_id_and_user_id(token.access_token_id, token.user_id)
          end

          def find_deploy_token_from_conan_jwt
            token = decode_oauth_token_from_jwt

            return unless token

            deploy_token = DeployToken.active.find_by_token(token.access_token_id.to_s)
            # note: uesr_id is not a user record id, but is the attribute set on ConanToken
            return if token.user_id != deploy_token&.username

            deploy_token
          end

          def find_job_from_conan_jwt
            token = decode_oauth_token_from_jwt

            return unless token

            ::Ci::AuthJobFinder.new(token: token.access_token_id.to_s).execute
          end

          def decode_oauth_token_from_jwt
            jwt = Doorkeeper::OAuth::Token.from_bearer_authorization(current_request)

            return unless jwt

            token = ::Gitlab::ConanToken.decode(jwt)

            return unless token && token.access_token_id && token.user_id

            token
          end

          def package_scope
            params[:id].present? ? :project : :instance
          end
        end
      end
    end
  end
end
