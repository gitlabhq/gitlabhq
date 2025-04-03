# frozen_string_literal: true

module API
  module Conan
    module V2
      class ProjectPackages < ::API::Base
        MAX_FILES_COUNT = 1000

        before do
          if Feature.disabled?(:conan_package_revisions_support, Feature.current_request)
            not_found!("'conan_package_revisions_support' feature flag is disabled")
          end
        end

        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
        end

        resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
          namespace ':id/packages/conan/v2' do
            include ::API::Concerns::Packages::Conan::SharedEndpoints
            params do
              with(type: String) do
                requires :package_name, regexp: PACKAGE_COMPONENT_REGEX,
                  desc: 'Package name', documentation: { example: 'my-package' }
                requires :package_version, regexp: PACKAGE_COMPONENT_REGEX,
                  desc: 'Package version', documentation: { example: '1.0' }
                requires :package_username, regexp: CONAN_REVISION_USER_CHANNEL_REGEX,
                  desc: 'Package username', documentation: { example: 'my-group+my-project' }
                requires :package_channel, regexp: CONAN_REVISION_USER_CHANNEL_REGEX,
                  desc: 'Package channel', documentation: { example: 'stable' }
              end
            end
            namespace 'conans/:package_name/:package_version/:package_username/:package_channel',
              requirements: PACKAGE_REQUIREMENTS do
              after_validation do
                check_username_channel
              end

              namespace 'latest' do
                desc 'Get the latest revision' do
                  detail 'This feature was introduced in GitLab 17.11'
                  success code: 200, model: ::API::Entities::Packages::Conan::RecipeRevision
                  failure [
                    { code: 400, message: 'Bad Request' },
                    { code: 401, message: 'Unauthorized' },
                    { code: 403, message: 'Forbidden' },
                    { code: 404, message: 'Not Found' }
                  ]
                  tags %w[conan_packages]
                end
                route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true
                route_setting :authorization, job_token_policies: :read_packages,
                  allow_public_access_for_enabled_project_features: :package_registry
                get urgency: :low do
                  not_found!('Package') unless package

                  revision = package.conan_recipe_revisions.order_by_id_desc.first

                  not_found!('Revision') unless revision.present?

                  present revision, with: ::API::Entities::Packages::Conan::RecipeRevision
                end
              end
              namespace 'revisions' do
                params do
                  requires :recipe_revision, type: String, regexp: Gitlab::Regex.conan_revision_regex_v2,
                    desc: 'Recipe revision', documentation: { example: 'df28fd816be3a119de5ce4d374436b25' }
                end
                namespace ':recipe_revision' do
                  namespace 'files' do
                    desc 'List recipe files' do
                      detail 'This feature was introduced in GitLab 17.11'
                      success code: 200, model: ::API::Entities::Packages::Conan::RecipeFilesList
                      failure [
                        { code: 400, message: 'Bad Request' },
                        { code: 401, message: 'Unauthorized' },
                        { code: 403, message: 'Forbidden' },
                        { code: 404, message: 'Not Found' }
                      ]
                      tags %w[conan_packages]
                    end
                    route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true
                    route_setting :authorization, job_token_policies: :read_packages,
                      allow_public_access_for_enabled_project_features: :package_registry
                    get urgency: :low do
                      not_found!('Package') unless package

                      files = ::Packages::Conan::PackageFilesFinder
                        .new(package, conan_file_type: :recipe_file, recipe_revision: params[:recipe_revision])
                        .execute
                        .limit(MAX_FILES_COUNT)
                        .select(:file_name)

                      not_found!('Recipe files') if files.empty?

                      present({ files: }, with: ::API::Entities::Packages::Conan::RecipeFilesList)
                    end

                    params do
                      requires :file_name, type: String, desc: 'Package file name', values: CONAN_FILES,
                        documentation: { example: 'conanfile.py' }
                    end
                    namespace ':file_name', requirements: FILE_NAME_REQUIREMENTS do
                      desc 'Download recipe files' do
                        detail 'This feature was introduced in GitLab 17.8'
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
                      route_setting :authorization, job_token_policies: :read_packages,
                        allow_public_access_for_enabled_project_features: :package_registry
                      get urgency: :low do
                        download_package_file(:recipe_file)
                      end

                      desc 'Upload recipe package files' do
                        detail 'This feature was introduced in GitLab 17.10'
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
                        requires :file, type: ::API::Validations::Types::WorkhorseFile,
                          desc: 'The package file to be published (generated by Multipart middleware)',
                          documentation: { type: 'file' }
                      end

                      route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true
                      route_setting :authorization, job_token_policies: :admin_packages

                      put urgency: :low do
                        upload_package_file(:recipe_file)
                      end

                      desc 'Workhorse authorize the conan recipe file' do
                        detail 'This feature was introduced in GitLab 17.10'
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
                      route_setting :authorization, job_token_policies: :admin_packages

                      put 'authorize', urgency: :low do
                        authorize_workhorse!(subject: project, maximum_size: project.actual_limits.conan_max_file_size)
                      end
                    end
                  end

                  params do
                    requires :conan_package_reference, type: String,
                      regexp: Gitlab::Regex.conan_package_reference_regex, desc: 'Package reference',
                      documentation: { example: '5ab84d6acfe1f23c4fae0ab88f26e3a396351ac9' }
                  end
                  namespace 'packages/:conan_package_reference' do
                    namespace 'revisions' do
                      params do
                        requires :package_revision, type: String, regexp: Gitlab::Regex.conan_revision_regex_v2,
                          desc: 'Package revision', documentation: { example: '3bdd2d8c8e76c876ebd1ac0469a4e72c' }
                      end
                      namespace ':package_revision' do
                        namespace 'files' do
                          params do
                            requires :file_name, type: String, desc: 'Package file name', values: CONAN_FILES,
                              documentation: { example: 'conaninfo.txt' }
                          end
                          namespace ':file_name', requirements: FILE_NAME_REQUIREMENTS do
                            desc 'Upload package files' do
                              detail 'This feature was introduced in GitLab 17.11'
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
                              requires :file, type: ::API::Validations::Types::WorkhorseFile,
                                desc: 'The package file to be published (generated by Multipart middleware)',
                                documentation: { type: 'file' }
                            end

                            route_setting :authentication, job_token_allowed: true,
                              basic_auth_personal_access_token: true
                            route_setting :authorization, job_token_policies: :admin_packages

                            put urgency: :low do
                              upload_package_file(:package_file)
                            end

                            desc 'Workhorse authorize the conan package file' do
                              detail 'This feature was introduced in GitLab 17.11'
                              success code: 200
                              failure [
                                { code: 400, message: 'Bad Request' },
                                { code: 401, message: 'Unauthorized' },
                                { code: 403, message: 'Forbidden' },
                                { code: 404, message: 'Not Found' }
                              ]
                              tags %w[conan_packages]
                            end

                            route_setting :authentication, job_token_allowed: true,
                              basic_auth_personal_access_token: true
                            route_setting :authorization, job_token_policies: :admin_packages

                            put 'authorize', urgency: :low do
                              authorize_workhorse!(subject: project,
                                maximum_size: project.actual_limits.conan_max_file_size)
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
        end
      end
    end
  end
end
