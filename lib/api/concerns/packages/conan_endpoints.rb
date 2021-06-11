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

        CONAN_FILES = (Gitlab::Regex::Packages::CONAN_RECIPE_FILES + Gitlab::Regex::Packages::CONAN_PACKAGE_FILES).freeze

        included do
          feature_category :package_registry

          helpers ::API::Helpers::PackagesManagerClientsHelpers
          helpers ::API::Helpers::Packages::Conan::ApiHelpers
          helpers ::API::Helpers::RelatedResourcesHelpers

          before do
            require_packages_enabled!

            # Personal access token will be extracted from Bearer or Basic authorization
            # in the overridden find_personal_access_token or find_user_from_job_token helpers
            authenticate_non_get!
          end

          desc 'Ping the Conan API' do
            detail 'This feature was introduced in GitLab 12.2'
          end

          route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true

          get 'ping' do
            header 'X-Conan-Server-Capabilities', [].join(',')
          end

          desc 'Search for packages' do
            detail 'This feature was introduced in GitLab 12.4'
          end

          params do
            requires :q, type: String, desc: 'Search query'
          end

          route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true

          get 'conans/search' do
            service = ::Packages::Conan::SearchService.new(current_user, query: params[:q]).execute
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
            end

            route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true

            get 'authenticate' do
              unauthorized! unless token

              token.to_jwt
            end

            desc 'Check for valid user credentials per conan CLI' do
              detail 'This feature was introduced in GitLab 12.4'
            end

            route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true

            get 'check_credentials' do
              authenticate!
              :ok
            end
          end

          params do
            requires :package_name, type: String, regexp: PACKAGE_COMPONENT_REGEX, desc: 'Package name'
            requires :package_version, type: String, regexp: PACKAGE_COMPONENT_REGEX, desc: 'Package version'
            requires :package_username, type: String, regexp: PACKAGE_COMPONENT_REGEX, desc: 'Package username'
            requires :package_channel, type: String, regexp: PACKAGE_COMPONENT_REGEX, desc: 'Package channel'
          end
          namespace 'conans/:package_name/:package_version/:package_username/:package_channel', requirements: PACKAGE_REQUIREMENTS do
            # Get the snapshot
            #
            # the snapshot is a hash of { filename: md5 hash }
            # md5 hash is the has of that file. This hash is used to diff the files existing on the client
            # to determine which client files need to be uploaded if no recipe exists the snapshot is empty
            desc 'Package Snapshot' do
              detail 'This feature was introduced in GitLab 12.5'
            end

            params do
              requires :conan_package_reference, type: String, desc: 'Conan package ID'
            end

            route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true

            get 'packages/:conan_package_reference' do
              authorize!(:read_package, project)

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
            end

            route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true

            get do
              authorize!(:read_package, project)

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
            end
            params do
              requires :conan_package_reference, type: String, desc: 'Conan package ID'
            end

            route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true

            get 'packages/:conan_package_reference/digest' do
              present_package_download_urls
            end

            desc 'Recipe Digest' do
              detail 'This feature was introduced in GitLab 12.5'
            end

            route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true

            get 'digest' do
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
            end

            params do
              requires :conan_package_reference, type: String, desc: 'Conan package ID'
            end

            route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true

            get 'packages/:conan_package_reference/download_urls' do
              present_package_download_urls
            end

            desc 'Recipe Download Urls' do
              detail 'This feature was introduced in GitLab 12.5'
            end

            route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true

            get 'download_urls' do
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
            end

            params do
              requires :conan_package_reference, type: String, desc: 'Conan package ID'
            end

            route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true

            post 'packages/:conan_package_reference/upload_urls' do
              authorize!(:read_package, project)

              status 200
              present package_upload_urls, with: ::API::Entities::ConanPackage::ConanUploadUrls
            end

            desc 'Recipe Upload Urls' do
              detail 'This feature was introduced in GitLab 12.4'
            end

            route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true

            post 'upload_urls' do
              authorize!(:read_package, project)

              status 200
              present recipe_upload_urls, with: ::API::Entities::ConanPackage::ConanUploadUrls
            end

            desc 'Delete Package' do
              detail 'This feature was introduced in GitLab 12.5'
            end

            route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true

            delete do
              authorize!(:destroy_package, project)

              track_package_event('delete_package', :conan, category: 'API::ConanPackages', user: current_user, project: project, namespace: project.namespace)

              package.destroy
            end
          end

          params do
            requires :package_name, type: String, regexp: PACKAGE_COMPONENT_REGEX, desc: 'Package name'
            requires :package_version, type: String, regexp: PACKAGE_COMPONENT_REGEX, desc: 'Package version'
            requires :package_username, type: String, regexp: PACKAGE_COMPONENT_REGEX, desc: 'Package username'
            requires :package_channel, type: String, regexp: PACKAGE_COMPONENT_REGEX, desc: 'Package channel'
            requires :recipe_revision, type: String, regexp: CONAN_REVISION_REGEX, desc: 'Conan Recipe Revision'
          end
          namespace 'files/:package_name/:package_version/:package_username/:package_channel/:recipe_revision', requirements: PACKAGE_REQUIREMENTS do
            before do
              authenticate_non_get!
            end

            params do
              requires :file_name, type: String, desc: 'Package file name', values: CONAN_FILES
            end
            namespace 'export/:file_name', requirements: FILE_NAME_REQUIREMENTS do
              desc 'Download recipe files' do
                detail 'This feature was introduced in GitLab 12.6'
              end

              route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true

              get do
                download_package_file(:recipe_file)
              end

              desc 'Upload recipe package files' do
                detail 'This feature was introduced in GitLab 12.6'
              end

              params do
                requires :file, type: ::API::Validations::Types::WorkhorseFile, desc: 'The package file to be published (generated by Multipart middleware)'
              end

              route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true

              put do
                upload_package_file(:recipe_file)
              end

              desc 'Workhorse authorize the conan recipe file' do
                detail 'This feature was introduced in GitLab 12.6'
              end

              route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true

              put 'authorize' do
                authorize_workhorse!(subject: project, maximum_size: project.actual_limits.conan_max_file_size)
              end
            end

            params do
              requires :conan_package_reference, type: String, desc: 'Conan Package ID'
              requires :package_revision, type: String, desc: 'Conan Package Revision'
              requires :file_name, type: String, desc: 'Package file name', values: CONAN_FILES
            end
            namespace 'package/:conan_package_reference/:package_revision/:file_name', requirements: FILE_NAME_REQUIREMENTS do
              desc 'Download package files' do
                detail 'This feature was introduced in GitLab 12.5'
              end

              route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true

              get do
                download_package_file(:package_file)
              end

              desc 'Workhorse authorize the conan package file' do
                detail 'This feature was introduced in GitLab 12.6'
              end

              route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true

              put 'authorize' do
                authorize_workhorse!(subject: project, maximum_size: project.actual_limits.conan_max_file_size)
              end

              desc 'Upload package files' do
                detail 'This feature was introduced in GitLab 12.6'
              end

              params do
                requires :file, type: ::API::Validations::Types::WorkhorseFile, desc: 'The package file to be published (generated by Multipart middleware)'
              end

              route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true

              put do
                upload_package_file(:package_file)
              end
            end
          end
        end
      end
    end
  end
end
