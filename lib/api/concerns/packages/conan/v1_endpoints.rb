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
      module Conan
        module V1Endpoints
          extend ActiveSupport::Concern
          include SharedEndpoints

          included do
            helpers do
              def x_conan_server_capabilities_header
                ['revisions']
              end
            end

            desc 'Verify availability of a Conan repository' do
              detail 'Verifies availability of a Conan repository.'
              success code: 200
              failure [
                { code: 404, message: 'Not Found' }
              ]
              tags %w[packages_conan]
            end

            route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true
            route_setting :authorization, skip_job_token_policies: true,
              skip_granular_token_authorization: :public_endpoint

            get 'ping', urgency: :default do
              header 'X-Conan-Server-Capabilities', x_conan_server_capabilities_header.join(',')
            end

            params do
              requires :package_name, type: String, regexp: SharedEndpoints::PACKAGE_COMPONENT_REGEX,
                desc: 'Package name', documentation: { example: 'my-package' }
              requires :package_version, type: String, regexp: SharedEndpoints::PACKAGE_COMPONENT_REGEX,
                desc: 'Package version', documentation: { example: '1.0' }
              requires :package_username, type: String, regexp: SharedEndpoints::CONAN_REVISION_USER_CHANNEL_REGEX,
                desc: 'Package username', documentation: { example: 'my-group+my-project' }
              requires :package_channel, type: String, regexp: SharedEndpoints::CONAN_REVISION_USER_CHANNEL_REGEX,
                desc: 'Package channel', documentation: { example: 'stable' }
            end
            namespace 'conans/:package_name/:package_version/:package_username/:package_channel',
              requirements: SharedEndpoints::PACKAGE_REQUIREMENTS do
              after_validation do
                check_username_channel
              end

              # Get the snapshot
              #
              # the snapshot is a hash of { filename: md5 hash }
              # md5 hash is the hash of that file. This hash is used to diff the files existing on the client
              # to determine which client files need to be uploaded if no recipe exists the snapshot is empty
              desc 'Retrieve a package snapshot' do
                detail 'Retrieves a snapshot of the files for a specified Conan package and reference. The snapshot ' \
                  'is a list of filenames with their associated MD5 hash.'
                success code: 200, model: ::API::Entities::Packages::Conan::PackageSnapshot
                failure [
                  { code: 400, message: 'Bad Request' },
                  { code: 403, message: 'Forbidden' },
                  { code: 404, message: 'Not Found' }
                ]
                tags %w[packages_conan]
              end

              params do
                requires :conan_package_reference, type: String, desc: 'Conan package ID',
                  documentation: { example: '103f6067a947f366ef91fc1b7da351c588d1827f' }
              end

              route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true
              route_setting :authorization, job_token_policies: :read_packages,
                allow_public_access_for_enabled_project_features: :package_registry,
                permissions: :read_conan_package, boundary_type: :project

              get 'packages/:conan_package_reference', urgency: :low do
                authorize_read_package!(project)

                presenter = ::Packages::Conan::PackagePresenter.new(
                  package,
                  current_user,
                  project,
                  conan_package_reference: params[:conan_package_reference]
                )

                present presenter, with: ::API::Entities::Packages::Conan::PackageSnapshot
              end

              desc 'Retrieve a recipe snapshot' do
                detail 'Retrieves a snapshot of the files for a specified Conan recipe. The snapshot is a list of ' \
                  'filenames with their associated MD5 hash.'
                success code: 200, model: ::API::Entities::Packages::Conan::RecipeSnapshot
                failure [
                  { code: 400, message: 'Bad Request' },
                  { code: 403, message: 'Forbidden' },
                  { code: 404, message: 'Not Found' }
                ]
                tags %w[packages_conan]
              end

              route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true
              route_setting :authorization, job_token_policies: :read_packages,
                allow_public_access_for_enabled_project_features: :package_registry,
                permissions: :read_conan_package, boundary_type: :project

              get urgency: :low do
                authorize_read_package!(project)

                presenter = ::Packages::Conan::PackagePresenter.new(package, current_user, project)

                present presenter, with: ::API::Entities::Packages::Conan::RecipeSnapshot
              end

              # Get the manifest
              # returns the download urls for the existing recipe in the registry
              #
              # the manifest is a hash of { filename: url }
              # where the url is the download url for the file
              desc 'Retrieve a package manifest' do
                detail 'Retrieves a manifest that includes a list of files and associated download URLs for a ' \
                  'specified package.'
                success code: 200, model: ::API::Entities::Packages::Conan::PackageManifest
                failure [
                  { code: 400, message: 'Bad Request' },
                  { code: 403, message: 'Forbidden' },
                  { code: 404, message: 'Not Found' }
                ]
                tags %w[packages_conan]
              end
              params do
                requires :conan_package_reference, type: String, desc: 'Conan package ID',
                  documentation: { example: '103f6067a947f366ef91fc1b7da351c588d1827f' }
              end

              route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true
              route_setting :authorization, job_token_policies: :read_packages,
                allow_public_access_for_enabled_project_features: :package_registry,
                permissions: :read_conan_package, boundary_type: :project

              get 'packages/:conan_package_reference/digest', urgency: :low do
                present_package_download_urls
              end

              desc 'Retrieve a recipe manifest' do
                detail 'Retrieves a manifest that includes a list of files and associated download URLs for a ' \
                  'specified recipe.'
                success code: 200, model: ::API::Entities::Packages::Conan::RecipeManifest
                failure [
                  { code: 400, message: 'Bad Request' },
                  { code: 403, message: 'Forbidden' },
                  { code: 404, message: 'Not Found' }
                ]
                tags %w[packages_conan]
              end

              route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true
              route_setting :authorization, job_token_policies: :read_packages,
                allow_public_access_for_enabled_project_features: :package_registry,
                permissions: :read_conan_package, boundary_type: :project

              get 'digest', urgency: :low do
                present_recipe_download_urls
              end

              # Get the download urls
              #
              # returns the download urls for the existing recipe or package in the registry
              #
              # the manifest is a hash of { filename: url }
              # where the url is the download url for the file
              desc 'List all package download URLs' do
                detail 'Lists all files and associated download URLs for a specified package in the package ' \
                  'registry. Returns the same payload as the package manifest endpoint.'
                success code: 200, model: ::API::Entities::Packages::Conan::PackageManifest
                failure [
                  { code: 400, message: 'Bad Request' },
                  { code: 403, message: 'Forbidden' },
                  { code: 404, message: 'Not Found' }
                ]
                tags %w[packages_conan]
              end

              params do
                requires :conan_package_reference, type: String, desc: 'Conan package ID',
                  documentation: { example: '103f6067a947f366ef91fc1b7da351c588d1827f' }
              end

              route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true
              route_setting :authorization, job_token_policies: :read_packages,
                allow_public_access_for_enabled_project_features: :package_registry,
                permissions: :read_conan_package, boundary_type: :project

              get 'packages/:conan_package_reference/download_urls', urgency: :low do
                present_package_download_urls
              end

              desc 'List all recipe download URLs' do
                detail 'Lists all files and associated download URLs for a specified recipe in the package ' \
                  'registry. Returns the same payload as the recipe manifest endpoint.'
                success code: 200, model: ::API::Entities::Packages::Conan::RecipeManifest
                failure [
                  { code: 400, message: 'Bad Request' },
                  { code: 403, message: 'Forbidden' },
                  { code: 404, message: 'Not Found' }
                ]
                tags %w[packages_conan]
              end

              route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true
              route_setting :authorization, job_token_policies: :read_packages,
                allow_public_access_for_enabled_project_features: :package_registry,
                permissions: :read_conan_package, boundary_type: :project

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
              desc 'List all package upload URLs' do
                detail 'Lists all the upload URLs for a specified collection of package files. The request must ' \
                  'include a JSON object with the name and size of the individual files.'
                success code: 200, model: ::API::Entities::Packages::Conan::UploadUrls
                failure [
                  { code: 400, message: 'Bad Request' },
                  { code: 403, message: 'Forbidden' },
                  { code: 404, message: 'Not Found' }
                ]
                tags %w[packages_conan]
              end

              params do
                requires :conan_package_reference, type: String, desc: 'Conan package ID',
                  documentation: { example: '103f6067a947f366ef91fc1b7da351c588d1827f' }
              end

              route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true
              route_setting :authorization, job_token_policies: :read_packages,
                allow_public_access_for_enabled_project_features: :package_registry,
                permissions: :upload_conan_package, boundary_type: :project

              post 'packages/:conan_package_reference/upload_urls', urgency: :low do
                authorize_read_package!(project)

                status 200
                present package_upload_urls, with: ::API::Entities::Packages::Conan::UploadUrls
              end

              desc 'List all recipe upload URLs' do
                detail 'Lists all the upload URLs for a specified collection of recipe files. The request must ' \
                  'include a JSON object with the name and size of the individual files.'
                success code: 200, model: ::API::Entities::Packages::Conan::UploadUrls
                failure [
                  { code: 400, message: 'Bad Request' },
                  { code: 403, message: 'Forbidden' },
                  { code: 404, message: 'Not Found' }
                ]
                tags %w[packages_conan]
              end

              route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true
              route_setting :authorization, job_token_policies: :read_packages,
                allow_public_access_for_enabled_project_features: :package_registry,
                permissions: :upload_conan_package, boundary_type: :project

              post 'upload_urls', urgency: :low do
                authorize_read_package!(project)

                status 200
                present recipe_upload_urls, with: ::API::Entities::Packages::Conan::UploadUrls
              end

              desc 'Delete a recipe and package' do
                detail 'Deletes a specified Conan recipe and associated package files from the package ' \
                  'registry.'
                success code: 200
                failure [
                  { code: 400, message: 'Bad Request' },
                  { code: 403, message: 'Forbidden' },
                  { code: 404, message: 'Not Found' }
                ]
                tags %w[packages_conan]
              end

              route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true
              route_setting :authorization, job_token_policies: :admin_packages,
                permissions: :delete_conan_package, boundary_type: :project

              delete urgency: :low do
                authorize!(:destroy_package, project)

                track_package_event('delete_package', :conan, category: 'API::ConanPackages', project: project,
                  namespace: project.namespace)

                package.destroy
              end
            end

            params do
              requires :package_name, type: String, regexp: SharedEndpoints::PACKAGE_COMPONENT_REGEX,
                desc: 'Package name', documentation: { example: 'my-package' }
              requires :package_version, type: String, regexp: SharedEndpoints::PACKAGE_COMPONENT_REGEX,
                desc: 'Package version', documentation: { example: '1.0' }
              requires :package_username, type: String, regexp: SharedEndpoints::CONAN_REVISION_USER_CHANNEL_REGEX,
                desc: 'Package username', documentation: { example: 'my-group+my-project' }
              requires :package_channel, type: String, regexp: SharedEndpoints::CONAN_REVISION_USER_CHANNEL_REGEX,
                desc: 'Package channel', documentation: { example: 'stable' }
              requires :recipe_revision, type: String, regexp: Gitlab::Regex.conan_revision_regex,
                desc: 'Conan Recipe Revision', documentation: { example: '0' }
            end
            namespace 'files/:package_name/:package_version/:package_username/:package_channel/:recipe_revision',
              requirements: SharedEndpoints::PACKAGE_REQUIREMENTS do
              before do
                authenticate_non_get!
              end

              after_validation do
                check_username_channel
              end

              params do
                requires :file_name, type: String, desc: 'Package file name', values: SharedEndpoints::CONAN_FILES,
                  documentation: { example: 'conanfile.py' }
              end

              namespace 'export/:file_name',
                requirements: SharedEndpoints::FILE_NAME_REQUIREMENTS do
                desc 'Retrieve a recipe file' do
                  detail 'Retrieves a specified recipe file from the package registry. You must use the download URL ' \
                    'returned from the recipe download URLs endpoint.'
                  success code: 200
                  failure [
                    { code: 400, message: 'Bad Request' },
                    { code: 403, message: 'Forbidden' },
                    { code: 404, message: 'Not Found' }
                  ]
                  tags %w[packages_conan]
                end

                route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true
                route_setting :authorization, job_token_policies: :read_packages,
                  allow_public_access_for_enabled_project_features: :package_registry,
                  permissions: :read_conan_package, boundary_type: :project

                get urgency: :low do
                  download_package_file(:recipe_file)
                end

                desc 'Upload a recipe file' do
                  detail 'Uploads a specified recipe file to the package registry. You must use the upload URL ' \
                    'returned from the recipe upload URLs endpoint.'
                  success code: 200
                  failure [
                    { code: 400, message: 'Bad Request' },
                    { code: 401, message: 'Unauthorized' },
                    { code: 403, message: 'Forbidden' },
                    { code: 404, message: 'Not Found' }
                  ]
                  tags %w[packages_conan]
                end

                params do
                  requires :file, type: ::API::Validations::Types::WorkhorseFile,
                    desc: 'The package file to be published (generated by Multipart middleware)',
                    documentation: { type: 'file' }
                end

                route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true
                route_setting :authorization, job_token_policies: :admin_packages,
                  permissions: :upload_conan_package, boundary_type: :project

                put urgency: :low do
                  upload_package_file(:recipe_file)
                end

                desc 'Workhorse authorize the Conan recipe file' do
                  detail 'Authorizes the Conan recipe file.'
                  success code: 200
                  failure [
                    { code: 400, message: 'Bad Request' },
                    { code: 401, message: 'Unauthorized' },
                    { code: 403, message: 'Forbidden' },
                    { code: 404, message: 'Not Found' }
                  ]
                  tags %w[packages_conan]
                end

                route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true
                route_setting :authorization, job_token_policies: :admin_packages,
                  skip_granular_token_authorization: :workhorse_pre_authorization

                put 'authorize', urgency: :low do
                  verify_checksum_deploy_header!
                  protect_package!(params[:package_name], :conan, project: project)
                  authorize_workhorse!(subject: project, maximum_size: project.actual_limits.conan_max_file_size)
                end
              end

              params do
                requires :conan_package_reference, type: String, desc: 'Conan Package ID',
                  documentation: { example: '103f6067a947f366ef91fc1b7da351c588d1827f' }
                requires :package_revision, type: String, desc: 'Conan Package Revision',
                  documentation: { example: '0' }
                requires :file_name, type: String, desc: 'Package file name', values: SharedEndpoints::CONAN_FILES,
                  documentation: { example: 'conaninfo.txt' }
              end
              namespace 'package/:conan_package_reference/:package_revision/:file_name',
                requirements: SharedEndpoints::FILE_NAME_REQUIREMENTS do
                desc 'Retrieve a package file' do
                  detail 'Retrieves a specified package file from the package registry. You must use the download ' \
                    'URL returned from the package download URLs endpoint.'
                  success code: 200
                  failure [
                    { code: 403, message: 'Forbidden' },
                    { code: 404, message: 'Not Found' }
                  ]
                  tags %w[packages_conan]
                end

                route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true
                route_setting :authorization, job_token_policies: :read_packages,
                  allow_public_access_for_enabled_project_features: :package_registry,
                  permissions: :read_conan_package, boundary_type: :project

                get urgency: :low do
                  download_package_file(:package_file)
                end

                desc 'Workhorse authorize the Conan package file' do
                  detail 'Authorizes the Conan package file.'
                  success code: 200
                  failure [
                    { code: 400, message: 'Bad Request' },
                    { code: 401, message: 'Unauthorized' },
                    { code: 403, message: 'Forbidden' },
                    { code: 404, message: 'Not Found' }
                  ]
                  tags %w[packages_conan]
                end

                route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true
                route_setting :authorization, job_token_policies: :admin_packages,
                  skip_granular_token_authorization: :workhorse_pre_authorization

                put 'authorize', urgency: :low do
                  verify_checksum_deploy_header!
                  protect_package!(params[:package_name], :conan, project: project)
                  authorize_workhorse!(subject: project, maximum_size: project.actual_limits.conan_max_file_size)
                end

                desc 'Upload a package file' do
                  detail 'Uploads a specified package file to the package registry. You must use the upload URL ' \
                    'returned from the package upload URLs endpoint.'
                  success code: 200
                  failure [
                    { code: 400, message: 'Bad Request' },
                    { code: 401, message: 'Unauthorized' },
                    { code: 403, message: 'Forbidden' },
                    { code: 404, message: 'Not Found' }
                  ]
                  tags %w[packages_conan]
                end

                params do
                  requires :file, type: ::API::Validations::Types::WorkhorseFile,
                    desc: 'The package file to be published (generated by Multipart middleware)',
                    documentation: { type: 'file' }
                end

                route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true
                route_setting :authorization, job_token_policies: :admin_packages,
                  permissions: :upload_conan_package, boundary_type: :project

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
end
