# frozen_string_literal: true

module API
  module Helpers
    module Packages
      module Conan
        module ApiHelpers
          include Gitlab::Utils::StrongMemoize

          def check_username_channel
            username = declared(params)[:package_username]
            channel = declared(params)[:package_channel]

            if username == ::Packages::Conan::Metadatum::NONE_VALUE && package_scope == :instance
              # at the instance level, username must not be empty (naming convention)
              # don't try to process the empty username and eagerly return not found.
              not_found!
            end

            ::Packages::Conan::Metadatum.validate_username_and_channel(username, channel) do |none_field|
              bad_request!("#{none_field} can't be solely blank")
            end
          end

          def present_download_urls(entity)
            authorize_read_package!(project)

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
            { upload_urls: file_names.select(&method(:recipe_file?)).index_with do |file_name|
                             build_recipe_file_upload_url(file_name)
                           end }
          end

          def package_upload_urls
            { upload_urls: file_names.select(&method(:package_file?)).index_with do |file_name|
                             build_package_file_upload_url(file_name)
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
              package_revision: ::Packages::Conan::FileMetadatum::DEFAULT_REVISION
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
              recipe_revision: ::Packages::Conan::FileMetadatum::DEFAULT_REVISION
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
            case package_scope
            when :project
              user_project(action: :read_package)
            when :instance
              full_path = ::Packages::Conan::Metadatum.full_path_from(package_username: params[:package_username])
              find_project!(full_path)
            end
          end
          strong_memoize_attr :project

          def package
            ::Packages::Conan::Package
              .for_projects(project)
              .with_name(params[:package_name])
              .with_version(params[:package_version])
              .with_conan_username(params[:package_username])
              .with_conan_channel(params[:package_channel])
              .order_created
              .not_pending_destruction
              .last
          end
          strong_memoize_attr :package

          def token
            if find_personal_access_token
              ::Gitlab::ConanToken.from_personal_access_token(access_token_from_request, find_personal_access_token)
            elsif deploy_token_from_request
              ::Gitlab::ConanToken.from_deploy_token(deploy_token_from_request)
            else
              ::Gitlab::ConanToken.from_job(find_job_from_token)
            end
          end
          strong_memoize_attr :token

          def download_package_file(file_type)
            authorize_read_package!(project)

            package_file = ::Packages::Conan::PackageFileFinder
              .new(
                package,
                params[:file_name].to_s,
                conan_file_type: file_type,
                conan_package_reference: params[:conan_package_reference]
              ).execute!

            track_package_event('pull_package', :conan, category: 'API::ConanPackages', project: project, namespace: project.namespace) if params[:file_name] == ::Packages::Conan::FileMetadatum::PACKAGE_BINARY

            present_package_file!(package_file)
          end

          def find_or_create_package
            return package if package

            service_response = ::Packages::Conan::CreatePackageService.new(
              project,
              current_user,
              params.merge(build: current_authenticated_job)
            ).execute

            if service_response.error?
              forbidden!(service_response.message) if service_response.cause.package_protected?
              bad_request!(service_response.message)
            end

            service_response[:package]
          end

          def track_push_package_event
            if params[:file_name] == ::Packages::Conan::FileMetadatum::PACKAGE_BINARY
              track_package_event('push_package', :conan, category: 'API::ConanPackages', project: project, namespace: project.namespace)
            end
          end

          def file_names
            json_payload = Gitlab::Json.parse(request.body.read)
            json_payload.keys
          rescue JSON::ParserError,
            Encoding::UndefinedConversionError,
            Encoding::InvalidByteSequenceError,
            Encoding::CompatibilityError
            nil
          rescue StandardError => e
            Gitlab::ErrorTracking.track_exception(e)
            bad_request!(nil)
          end

          def create_package_file_with_type(file_type, current_package)
            unless params[:file].empty_size?
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

            track_push_package_event unless params[:file].empty_size?

            service_response = create_package_file_with_type(file_type, current_package)
            return unless service_response

            bad_request!(service_response.message) if service_response.error?

            service_response[:package_file]
          rescue ObjectStorage::RemoteStoreError => e
            Gitlab::ErrorTracking.track_exception(e, file_name: params[:file_name], project_id: project.id)

            forbidden!
          end

          # We override this method from auth_finders because we need to
          # extract the token from the Conan JWT which is specific to the Conan API
          def find_personal_access_token
            PersonalAccessToken.active.find_by_token(access_token_from_request)
          end
          strong_memoize_attr :find_personal_access_token

          def access_token_from_request
            find_personal_access_token_from_conan_jwt ||
              find_password_from_basic_auth
          end
          strong_memoize_attr :access_token_from_request

          def find_password_from_basic_auth
            return unless route_authentication_setting[:basic_auth_personal_access_token]
            return unless has_basic_credentials?(current_request)

            _username, password = user_name_and_password(current_request)
            password
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
          def find_oauth_access_token; end

          def find_personal_access_token_from_conan_jwt
            token = decode_oauth_token_from_jwt

            return unless token

            token.access_token_id
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

          def search_project
            project
          end
        end
      end
    end
  end
end
