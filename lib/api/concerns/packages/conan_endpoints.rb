# frozen_string_literal: true

# Conan Package Manager Client API
#
# These API endpoints are not consumed directly by users, so there is no documentation for the
# individual endpoints. They are called by the Conan package manager client when users run commands
# like `conan install` or `conan upload`. The usage of the GitLab Conan repository is documented here:
# https://docs.gitlab.com/ee/user/packages/conan_repository/#installing-a-package
#
# Technical debt: https://gitlab.com/gitlab-org/gitlab/issues/35798
module API
  module Concerns
    module Packages
      module ConanEndpoints
        extend ActiveSupport::Concern

        PACKAGE_REQUIREMENTS = {
          package_name: API::NO_SLASH_URL_PART_REGEX,
          package_version: API::NO_SLASH_URL_PART_REGEX,
          package_username: API::NO_SLASH_URL_PART_REGEX,
          package_channel: API::NO_SLASH_URL_PART_REGEX
        }.freeze

        FILE_NAME_REQUIREMENTS = {
          file_name: API::NO_SLASH_URL_PART_REGEX
        }.freeze

        PACKAGE_COMPONENT_REGEX = Gitlab::Regex.conan_recipe_component_regex
        CONAN_REVISION_REGEX = Gitlab::Regex.conan_revision_regex
        CONAN_REVISION_USER_CHANNEL_REGEX = Gitlab::Regex.conan_recipe_user_channel_regex

        CONAN_FILES = (Gitlab::Regex::Packages::CONAN_RECIPE_FILES + Gitlab::Regex::Packages::CONAN_PACKAGE_FILES).uniq.freeze

        included do
          feature_category :package_registry

          helpers ::API::Helpers::PackagesManagerClientsHelpers
          helpers ::API::Helpers::Packages::Conan::ApiHelpers
          helpers ::API::Helpers::RelatedResourcesHelpers

          rescue_from ActiveRecord::RecordInvalid do |e|
            render_api_error!(e.message, 400)
          end

          before do
            not_found! if Gitlab::FIPS.enabled?
            require_packages_enabled!

            # Personal access token will be extracted from Bearer or Basic authorization
            # in the overridden find_personal_access_token or find_user_from_job_token helpers
            authenticate_non_get!
          end

          desc 'Ping the Conan API' do
            detail 'This feature was introduced in GitLab 12.2'
            success code: 200
            failure [
              { code: 404, message: 'Not Found' }
            ]
            tags %w[conan_packages]
          end

          route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true

          get 'ping', urgency: :default do
            header 'X-Conan-Server-Capabilities', [].join(',')
          end

          desc 'Search for packages' do
            detail 'This feature was introduced in GitLab 12.4'
            success code: 200
            failure [
              { code: 404, message: 'Not Found' }
            ]
            tags %w[conan_packages]
          end

          params do
            requires :q, type: String, desc: 'Search query', documentation: { example: 'Hello*' }
          end

          route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true

          get 'conans/search', urgency: :low do
            service = ::Packages::Conan::SearchService.new(search_project, current_user, query: params[:q]).execute

            service.payload
          end

          namespace 'users' do
            before do
              authenticate!
            end

            format :txt
            content_type :txt, 'text/plain'

            desc 'Authenticate user against conan CLI' do
              detail 'This feature was introduced in GitLab 12.2'
              success code: 200
              failure [
                { code: 401, message: 'Unauthorized' },
                { code: 404, message: 'Not Found' }
              ]
              tags %w[conan_packages]
            end

            route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true

            get 'authenticate', urgency: :low do
              unauthorized! unless token

              token.to_jwt
            end

            desc 'Check for valid user credentials per conan CLI' do
              detail 'This feature was introduced in GitLab 12.4'
              success code: 200
              failure [
                { code: 401, message: 'Unauthorized' },
                { code: 404, message: 'Not Found' }
              ]
              tags %w[conan_packages]
            end

            route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true

            get 'check_credentials', urgency: :default do
              authenticate!
              :ok
            end
          end

          params do
            requires :package_name, type: String, regexp: PACKAGE_COMPONENT_REGEX, desc: 'Package name', documentation: { example: 'my-package' }
            requires :package_version, type: String, regexp: PACKAGE_COMPONENT_REGEX, desc: 'Package version', documentation: { example: '1.0' }
            requires :package_username, type: String, regexp: CONAN_REVISION_USER_CHANNEL_REGEX, desc: 'Package username', documentation: { example: 'my-group+my-project' }
            requires :package_channel, type: String, regexp: CONAN_REVISION_USER_CHANNEL_REGEX, desc: 'Package channel', documentation: { example: 'stable' }
          end
          namespace 'conans/:package_name/:package_version/:package_username/:package_channel', requirements: PACKAGE_REQUIREMENTS do
            after_validation do
              check_username_channel
            end

            # Get the snapshot
            #
            # the snapshot is a hash of { filename: md5 hash }
            # md5 hash is the hash of that file. This hash is used to diff the files existing on the client
            # to determine which client files need to be uploaded if no recipe exists the snapshot is empty
            desc 'Package Snapshot' do
              detail 'This feature was introduced in GitLab 12.5'
              success code: 200, model: ::API::Entities::ConanPackage::ConanPackageSnapshot
              failure [
                { code: 400, message: 'Bad Request' },
                { code: 403, message: 'Forbidden' },
                { code: 404, message: 'Not Found' }
              ]
              tags %w[conan_packages]
            end

            params do
              requires :conan_package_reference, type: String, desc: 'Conan package ID', documentation: { example: '103f6067a947f366ef91fc1b7da351c588d1827f' }
            end

            route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true

            get 'packages/:conan_package_reference', urgency: :low do
              authorize_read_package!(project)

              presenter = ::Packages::Conan::PackagePresenter.new(
                package,
                current_user,
                project,
                conan_package_reference: params[:conan_package_reference]
              )

              present presenter, with: ::API::Entities::ConanPackage::ConanPackageSnapshot
            end

            desc 'Recipe Snapshot' do
              detail 'This feature was introduced in GitLab 12.5'
              success code: 200, model: ::API::Entities::ConanPackage::ConanRecipeSnapshot
              failure [
                { code: 400, message: 'Bad Request' },
                { code: 403, message: 'Forbidden' },
                { code: 404, message: 'Not Found' }
              ]
              tags %w[conan_packages]
            end

            route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true

            get urgency: :low do
              authorize_read_package!(project)

              presenter = ::Packages::Conan::PackagePresenter.new(package, current_user, project)

              present presenter, with: ::API::Entities::ConanPackage::ConanRecipeSnapshot
            end

            # Get the manifest
            # returns the download urls for the existing recipe in the registry
            #
            # the manifest is a hash of { filename: url }
            # where the url is the download url for the file
            desc 'Package Digest' do
              detail 'This feature was introduced in GitLab 12.5'
              success code: 200, model: ::API::Entities::ConanPackage::ConanPackageManifest
              failure [
                { code: 400, message: 'Bad Request' },
                { code: 403, message: 'Forbidden' },
                { code: 404, message: 'Not Found' }
              ]
              tags %w[conan_packages]
            end
            params do
              requires :conan_package_reference, type: String, desc: 'Conan package ID', documentation: { example: '103f6067a947f366ef91fc1b7da351c588d1827f' }
            end

            route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true

            get 'packages/:conan_package_reference/digest', urgency: :low do
              present_package_download_urls
            end

            desc 'Recipe Digest' do
              detail 'This feature was introduced in GitLab 12.5'
              success code: 200, model: ::API::Entities::ConanPackage::ConanRecipeManifest
              failure [
                { code: 400, message: 'Bad Request' },
                { code: 403, message: 'Forbidden' },
                { code: 404, message: 'Not Found' }
              ]
              tags %w[conan_packages]
            end

            route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true

            get 'digest', urgency: :low do
              present_recipe_download_urls
            end

            # Get the download urls
            #
            # returns the download urls for the existing recipe or package in the registry
            #
            # the manifest is a hash of { filename: url }
            # where the url is the download url for the file
            desc 'Package Download Urls' do
              detail 'This feature was introduced in GitLab 12.5'
              success code: 200, model: ::API::Entities::ConanPackage::ConanPackageManifest
              failure [
                { code: 400, message: 'Bad Request' },
                { code: 403, message: 'Forbidden' },
                { code: 404, message: 'Not Found' }
              ]
              tags %w[conan_packages]
            end

            params do
              requires :conan_package_reference, type: String, desc: 'Conan package ID', documentation: { example: '103f6067a947f366ef91fc1b7da351c588d1827f' }
            end

            route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true

            get 'packages/:conan_package_reference/download_urls', urgency: :low do
              present_package_download_urls
            end

            desc 'Recipe Download Urls' do
              detail 'This feature was introduced in GitLab 12.5'
              success code: 200, model: ::API::Entities::ConanPackage::ConanRecipeManifest
              failure [
                { code: 400, message: 'Bad Request' },
                { code: 403, message: 'Forbidden' },
                { code: 404, message: 'Not Found' }
              ]
              tags %w[conan_packages]
            end

            route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true

            get 'download_urls', urgency: :low do
              present_recipe_download_urls
            end

            # Get the upload urls
            #
            # request body contains { filename: filesize } where the filename is the
            # name of the file the conan client is requesting to upload
            #
            # returns { filename: url }
            # where the url is the upload url for the file that the conan client will use
            desc 'Package Upload Urls' do
              detail 'This feature was introduced in GitLab 12.4'
              success code: 200, model: ::API::Entities::ConanPackage::ConanUploadUrls
              failure [
                { code: 400, message: 'Bad Request' },
                { code: 403, message: 'Forbidden' },
                { code: 404, message: 'Not Found' }
              ]
              tags %w[conan_packages]
            end

            params do
              requires :conan_package_reference, type: String, desc: 'Conan package ID', documentation: { example: '103f6067a947f366ef91fc1b7da351c588d1827f' }
            end

            route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true

            post 'packages/:conan_package_reference/upload_urls', urgency: :low do
              authorize_read_package!(project)

              status 200
              present package_upload_urls, with: ::API::Entities::ConanPackage::ConanUploadUrls
            end

            desc 'Recipe Upload Urls' do
              detail 'This feature was introduced in GitLab 12.4'
              success code: 200, model: ::API::Entities::ConanPackage::ConanUploadUrls
              failure [
                { code: 400, message: 'Bad Request' },
                { code: 403, message: 'Forbidden' },
                { code: 404, message: 'Not Found' }
              ]
              tags %w[conan_packages]
            end

            route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true

            post 'upload_urls', urgency: :low do
              authorize_read_package!(project)

              status 200
              present recipe_upload_urls, with: ::API::Entities::ConanPackage::ConanUploadUrls
            end

            desc 'Delete Package' do
              detail 'This feature was introduced in GitLab 12.5'
              success code: 200
              failure [
                { code: 400, message: 'Bad Request' },
                { code: 403, message: 'Forbidden' },
                { code: 404, message: 'Not Found' }
              ]
              tags %w[conan_packages]
            end

            route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true

            delete urgency: :low do
              authorize!(:destroy_package, project)

              track_package_event('delete_package', :conan, category: 'API::ConanPackages', project: project, namespace: project.namespace)

              package.destroy
            end
          end

          params do
            requires :package_name, type: String, regexp: PACKAGE_COMPONENT_REGEX, desc: 'Package name', documentation: { example: 'my-package' }
            requires :package_version, type: String, regexp: PACKAGE_COMPONENT_REGEX, desc: 'Package version', documentation: { example: '1.0' }
            requires :package_username, type: String, regexp: CONAN_REVISION_USER_CHANNEL_REGEX, desc: 'Package username', documentation: { example: 'my-group+my-project' }
            requires :package_channel, type: String, regexp: CONAN_REVISION_USER_CHANNEL_REGEX, desc: 'Package channel', documentation: { example: 'stable' }
            requires :recipe_revision, type: String, regexp: CONAN_REVISION_REGEX, desc: 'Conan Recipe Revision', documentation: { example: '0' }
          end
          namespace 'files/:package_name/:package_version/:package_username/:package_channel/:recipe_revision', requirements: PACKAGE_REQUIREMENTS do
            before do
              authenticate_non_get!
            end

            after_validation do
              check_username_channel
            end

            params do
              requires :file_name, type: String, desc: 'Package file name', values: CONAN_FILES, documentation: { example: 'conanfile.py' }
            end

            namespace 'export/:file_name', requirements: FILE_NAME_REQUIREMENTS do
              desc 'Download recipe files' do
                detail 'This feature was introduced in GitLab 12.6'
                success code: 200
                failure [
                  { code: 400, message: 'Bad Request' },
                  { code: 403, message: 'Forbidden' },
                  { code: 404, message: 'Not Found' }
                ]
                tags %w[conan_packages]
              end

              route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true

              get urgency: :low do
                download_package_file(:recipe_file)
              end

              desc 'Upload recipe package files' do
                detail 'This feature was introduced in GitLab 12.6'
                success code: 200
                failure [
                  { code: 400, message: 'Bad Request' },
                  { code: 401, message: 'Unauthorized' },
                  { code: 403, message: 'Forbidden' },
                  { code: 404, message: 'Not Found' }
                ]
                tags %w[conan_packages]
              end

              params do
                requires :file, type: ::API::Validations::Types::WorkhorseFile, desc: 'The package file to be published (generated by Multipart middleware)', documentation: { type: 'file' }
              end

              route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true

              put urgency: :low do
                upload_package_file(:recipe_file)
              end

              desc 'Workhorse authorize the conan recipe file' do
                detail 'This feature was introduced in GitLab 12.6'
                success code: 200
                failure [
                  { code: 400, message: 'Bad Request' },
                  { code: 401, message: 'Unauthorized' },
                  { code: 403, message: 'Forbidden' },
                  { code: 404, message: 'Not Found' }
                ]
                tags %w[conan_packages]
              end

              route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true

              put 'authorize', urgency: :low do
                authorize_workhorse!(subject: project, maximum_size: project.actual_limits.conan_max_file_size)
              end
            end

            params do
              requires :conan_package_reference, type: String, desc: 'Conan Package ID', documentation: { example: '103f6067a947f366ef91fc1b7da351c588d1827f' }
              requires :package_revision, type: String, desc: 'Conan Package Revision', documentation: { example: '0' }
              requires :file_name, type: String, desc: 'Package file name', values: CONAN_FILES, documentation: { example: 'conaninfo.txt' }
            end
            namespace 'package/:conan_package_reference/:package_revision/:file_name', requirements: FILE_NAME_REQUIREMENTS do
              desc 'Download package files' do
                detail 'This feature was introduced in GitLab 12.5'
                success code: 200
                failure [
                  { code: 403, message: 'Forbidden' },
                  { code: 404, message: 'Not Found' }
                ]
                tags %w[conan_packages]
              end

              route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true

              get urgency: :low do
                download_package_file(:package_file)
              end

              desc 'Workhorse authorize the conan package file' do
                detail 'This feature was introduced in GitLab 12.6'
                success code: 200
                failure [
                  { code: 400, message: 'Bad Request' },
                  { code: 401, message: 'Unauthorized' },
                  { code: 403, message: 'Forbidden' },
                  { code: 404, message: 'Not Found' }
                ]
                tags %w[conan_packages]
              end

              route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true

              put 'authorize', urgency: :low do
                authorize_workhorse!(subject: project, maximum_size: project.actual_limits.conan_max_file_size)
              end

              desc 'Upload package files' do
                detail 'This feature was introduced in GitLab 12.6'
                success code: 200
                failure [
                  { code: 400, message: 'Bad Request' },
                  { code: 401, message: 'Unauthorized' },
                  { code: 403, message: 'Forbidden' },
                  { code: 404, message: 'Not Found' }
                ]
                tags %w[conan_packages]
              end

              params do
                requires :file, type: ::API::Validations::Types::WorkhorseFile, desc: 'The package file to be published (generated by Multipart middleware)', documentation: { type: 'file' }
              end

              route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true

              put urgency: :low do
                upload_package_file(:package_file)
              end
            end
          end
        end
      end
    end
  end
end
