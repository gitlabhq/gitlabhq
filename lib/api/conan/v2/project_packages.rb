# frozen_string_literal: true

module API
  module Conan
    module V2
      class ProjectPackages < ::API::Base
        MAX_FILES_COUNT = MAX_PACKAGE_REVISIONS_COUNT = 1000

        helpers do
          include Gitlab::Utils::StrongMemoize
          def package_files(finder_params)
            ::Packages::Conan::PackageFilesFinder
              .new(package, **finder_params)
              .execute
              .limit(MAX_FILES_COUNT)
              .select(:file_name)
          end

          def track_conan_package_event(event)
            track_package_event(event, :conan, category: 'API::ConanPackages', project: project,
              namespace: project.namespace)
          end

          def destroy_package_entity(entity, event_name)
            track_conan_package_event(event_name)

            entity.transaction do
              ::Packages::MarkPackageFilesForDestructionService.new(entity.package_files).execute
              destroy_conditionally!(entity) do
                entity.destroy

                # Conan cli expects 200 status code when deleting
                status 200
              end
            end
          end

          def recipe_revision
            package.conan_recipe_revisions.find_by_revision(params[:recipe_revision])
          end
          strong_memoize_attr :recipe_revision

          def package_revisions
            package.conan_package_revisions
              .by_recipe_revision_and_package_reference(params[:recipe_revision],
                params[:conan_package_reference])
          end

          def package_revision
            package_revisions.find_by_revision(params[:package_revision])
          end
          strong_memoize_attr :package_revision
        end

        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
        end

        resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
          namespace ':id/packages/conan/v2' do
            include ::API::Concerns::Packages::Conan::SharedEndpoints
            params do
              requires :package_name, type: String, regexp: PACKAGE_COMPONENT_REGEX,
                desc: 'Package name', documentation: { example: 'my-package' }
              requires :package_version, type: String, regexp: PACKAGE_COMPONENT_REGEX,
                desc: 'Package version', documentation: { example: '1.0' }
              requires :package_username, type: String, regexp: CONAN_REVISION_USER_CHANNEL_REGEX,
                desc: 'Package username', documentation: { example: 'my-group+my-project' }
              requires :package_channel, type: String, regexp: CONAN_REVISION_USER_CHANNEL_REGEX,
                desc: 'Package channel', documentation: { example: 'stable' }
            end
            namespace 'conans/:package_name/:package_version/:package_username/:package_channel',
              requirements: PACKAGE_REQUIREMENTS do
              after_validation do
                check_username_channel
              end

              namespace 'latest' do
                desc 'Get the latest recipe revision' do
                  detail 'This feature was introduced in GitLab 17.11'
                  success code: 200, model: ::API::Entities::Packages::Conan::Revision
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

                  present revision, with: ::API::Entities::Packages::Conan::Revision
                end
              end
              namespace 'revisions' do
                desc 'Get the list of revisions' do
                  detail 'This feature was introduced in GitLab 17.11'
                  success code: 200, model: ::API::Entities::Packages::Conan::RecipeRevisions
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

                  present package, with: ::API::Entities::Packages::Conan::RecipeRevisions
                end
                params do
                  requires :recipe_revision, type: String, regexp: Gitlab::Regex.conan_revision_regex_v2,
                    desc: 'Recipe revision', documentation: { example: 'df28fd816be3a119de5ce4d374436b25' }
                end
                namespace ':recipe_revision' do
                  desc 'Delete recipe revision' do
                    detail 'This feature was introduced in GitLab 18.1'
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

                  delete urgency: :low do
                    authorize_destroy_package!(project)

                    not_found!('Package') unless package

                    not_found!('Revision') unless recipe_revision

                    if package.conan_recipe_revisions.one?
                      track_conan_package_event('delete_package')
                      destroy_conditionally!(package) do |package|
                        ::Packages::MarkPackageForDestructionService.new(container: package,
                          current_user: current_user).execute

                        # Conan cli expects 200 status code when deleting a recipe revision
                        status 200
                      end
                    else
                      if recipe_revision.package_files.size > MAX_FILES_COUNT
                        unprocessable_entity! "Cannot delete more than #{MAX_FILES_COUNT} files"
                      end

                      destroy_package_entity(recipe_revision, 'delete_recipe_revision')
                    end
                  end

                  namespace 'files' do
                    desc 'List recipe files' do
                      detail 'This feature was introduced in GitLab 17.11'
                      success code: 200, model: ::API::Entities::Packages::Conan::FilesList
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

                      files = package_files(conan_file_type: :recipe_file, recipe_revision: params[:recipe_revision])
                      not_found!('Recipe files') if files.empty?

                      present({ files: }, with: ::API::Entities::Packages::Conan::FilesList)
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

                  desc 'Get package references metadata' do
                    detail 'This feature was introduced in GitLab 18.1'
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
                  route_setting :authorization,  job_token_policies: :read_packages,
                    allow_public_access_for_enabled_project_features: :package_registry

                  get 'search', urgency: :low do
                    check_username_channel

                    authorize_read_package!(project)
                    not_found!('Package') unless package
                    not_found!('Revision') unless recipe_revision.present?

                    recipe_revision.conan_package_references.pluck_reference_and_info.to_h
                  end

                  params do
                    requires :conan_package_reference, type: String,
                      regexp: Gitlab::Regex.conan_package_reference_regex, desc: 'Package reference',
                      documentation: { example: '5ab84d6acfe1f23c4fae0ab88f26e3a396351ac9' }
                  end
                  namespace 'packages/:conan_package_reference' do
                    namespace 'latest' do
                      desc 'Get the latest package revision' do
                        detail 'This feature was introduced in GitLab 17.11'
                        success code: 200, model: ::API::Entities::Packages::Conan::Revision
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

                        revision = package_revisions.order_by_id_desc.first

                        not_found!('Revision') unless revision.present?

                        present revision, with: ::API::Entities::Packages::Conan::Revision
                      end
                    end
                    namespace 'revisions' do
                      desc 'Get the list of package revisions' do
                        detail 'This feature was introduced in GitLab 18.0'
                        success code: 200, model: ::API::Entities::Packages::Conan::PackageRevisions
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

                        revisions = package_revisions
                          .order_by_id_desc
                          .limit(MAX_PACKAGE_REVISIONS_COUNT)

                        package_reference = "#{package.conan_recipe}##{params[:recipe_revision]}:" \
                          "#{params[:conan_package_reference]}"
                        present({ package_reference: package_reference, package_revisions: revisions },
                          with: ::API::Entities::Packages::Conan::PackageRevisions)
                      end

                      params do
                        requires :package_revision, type: String, regexp: Gitlab::Regex.conan_revision_regex_v2,
                          desc: 'Package revision', documentation: { example: '3bdd2d8c8e76c876ebd1ac0469a4e72c' }
                      end
                      namespace ':package_revision' do
                        desc 'Delete package revision' do
                          detail 'This feature was introduced in GitLab 18.1'
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

                        delete urgency: :low do
                          authorize_destroy_package!(project)

                          not_found!('Package') unless package

                          not_found!('Package Revision') unless package_revision

                          if package_revision.package_files.size > MAX_FILES_COUNT
                            unprocessable_entity! "Cannot delete more than #{MAX_FILES_COUNT} files"
                          end

                          if package_revisions.one?
                            destroy_package_entity(package_revision.package_reference, 'delete_package_reference')
                          else
                            destroy_package_entity(package_revision, 'delete_package_revision')
                          end
                        end
                        namespace 'files' do
                          desc 'List package files' do
                            detail 'This feature was introduced in GitLab 18.0'
                            success code: 200, model: ::API::Entities::Packages::Conan::FilesList
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

                            files = package_files(conan_file_type: :package_file,
                              recipe_revision: params[:recipe_revision],
                              conan_package_reference: params[:conan_package_reference],
                              package_revision: params[:package_revision])

                            not_found!('Package files') if files.empty?

                            present({ files: }, with: ::API::Entities::Packages::Conan::FilesList)
                          end

                          params do
                            requires :file_name, type: String, desc: 'Package file name', values: CONAN_FILES,
                              documentation: { example: 'conaninfo.txt' }
                          end
                          namespace ':file_name', requirements: FILE_NAME_REQUIREMENTS do
                            desc 'Download package files' do
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
                            route_setting :authorization, job_token_policies: :read_packages,
                              allow_public_access_for_enabled_project_features: :package_registry
                            get urgency: :low do
                              download_package_file(:package_file)
                            end

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
