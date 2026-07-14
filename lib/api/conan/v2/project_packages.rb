# frozen_string_literal: true

module API
  module Conan
    module V2
      class ProjectPackages < ::API::Base
        MAX_FILES_COUNT = MAX_PACKAGE_REVISIONS_COUNT = 1000

        def self.authorization_boundary_options
          { boundary_type: :project }
        end

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
            if ::Feature.enabled?(:packages_protected_packages_delete, project)
              service_response = ::Packages::Protection::CheckRuleExistenceService.for_delete(
                project: project,
                current_user: current_user,
                params: { package_name: package.name, package_type: :conan }
              ).execute

              forbidden!('Package is deletion protected.') if service_response[:protection_rule_exists?]
            end

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

          def v1_revisions_backward_compatibility_enabled?
            Feature.enabled?(:packages_conan_v1_revisions_backward_compatibility, project)
          end

          def default_recipe_revision?
            params[:recipe_revision] == ::Packages::Conan::FileMetadatum::DEFAULT_REVISION
          end

          # v1 packages have files but no recipe/package revision records. We only fall back
          # to the default "0" revision when installable v1 files exist, so files that are
          # pending destruction or errored cannot advertise a phantom revision.
          def v1_recipe_revision_fallback?
            v1_revisions_backward_compatibility_enabled? &&
              package.installable_package_files.without_conan_recipe_revision.exists?
          end

          def v1_package_revision_fallback?
            v1_revisions_backward_compatibility_enabled? &&
              default_recipe_revision? &&
              package.installable_package_files
                .with_conan_package_reference(params[:conan_package_reference])
                .without_conan_recipe_revision
                .without_conan_package_revision.exists?
          end

          def latest_recipe_revision
            package.conan_recipe_revisions.default.order_by_id_desc.first ||
              (package.default_recipe_revision if v1_recipe_revision_fallback?)
          end

          def latest_package_revision
            package_revisions.default.order_by_id_desc.first ||
              (package.default_package_revision if v1_package_revision_fallback?)
          end

          def package_references_for_recipe_revision
            return recipe_revision.conan_package_references if recipe_revision
            return unless default_recipe_revision?
            return unless v1_recipe_revision_fallback?

            # Scope to refs without a recipe revision so mixed v1+v2 packages do not leak v2
            # refs, and to refs backed by installable v1 files so orphaned or partially-cleaned
            # references are not advertised through the fallback path.
            package.conan_package_references.without_recipe_revision.with_installable_package_files
          end
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
                desc 'Retrieve latest recipe revision' do
                  detail 'Retrieves the revision hash and creation date of the latest package recipe. This feature ' \
                    'was introduced in GitLab 17.11.'
                  success code: 200, model: ::API::Entities::Packages::Conan::Revision
                  failure [
                    { code: 400, message: 'Bad Request' },
                    { code: 401, message: 'Unauthorized' },
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
                  not_found!('Package') unless package

                  revision = latest_recipe_revision

                  not_found!('Revision') unless revision
                  present revision, with: ::API::Entities::Packages::Conan::Revision
                end
              end
              namespace 'revisions' do
                desc 'List all recipe revisions' do
                  detail 'Lists all revisions for a package recipe. This feature was introduced in GitLab 17.11.'
                  success code: 200, model: ::API::Entities::Packages::Conan::RecipeRevisions
                  failure [
                    { code: 400, message: 'Bad Request' },
                    { code: 401, message: 'Unauthorized' },
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
                  not_found!('Package') unless package

                  present package, with: ::API::Entities::Packages::Conan::RecipeRevisions
                end
                params do
                  requires :recipe_revision, type: String, regexp: Gitlab::Regex.conan_revision_regex_combined,
                    desc: 'Recipe revision', documentation: { example: 'df28fd816be3a119de5ce4d374436b25' }
                end
                namespace ':recipe_revision' do
                  desc 'Delete recipe revision' do
                    detail 'Deletes a specified recipe revision from the registry. If the recipe revision is the ' \
                      'only one, the package is deleted as well. This feature was introduced in GitLab 18.1.'
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
                    permissions: :delete_conan_package, boundary_type: :project

                  delete urgency: :low do
                    authorize_destroy_package!(project)

                    not_found!('Package') unless package

                    not_found!('Revision') unless recipe_revision

                    if package.conan_recipe_revisions.one?
                      destroy_conditionally!(package) do |package|
                        result = ::Packages::MarkPackageForDestructionService.new(container: package,
                          current_user: current_user).execute
                        render_api_error!(result.message, result.http_status) if result.error?

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
                    desc 'List all recipe files' do
                      detail 'Lists all recipe files from the package registry. This feature was introduced in ' \
                        'GitLab 17.11.'
                      success code: 200, model: ::API::Entities::Packages::Conan::FilesList
                      failure [
                        { code: 400, message: 'Bad Request' },
                        { code: 401, message: 'Unauthorized' },
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
                      desc 'Retrieve a recipe file' do
                        detail 'Retrieves a specified recipe file from the package registry. This feature was ' \
                          'introduced in GitLab 17.8.'
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
                      route_setting :authorization, job_token_policies: :read_packages,
                        allow_public_access_for_enabled_project_features: :package_registry,
                        permissions: :read_conan_package, boundary_type: :project
                      get urgency: :low do
                        download_package_file(:recipe_file)
                      end

                      desc 'Upload a recipe file' do
                        detail 'Uploads a specified recipe file to the package registry. This feature was introduced ' \
                          'in GitLab 17.10.'
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
                        detail 'Authorizes the Conan recipe file. This feature was introduced in GitLab 17.10.'
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
                        protect_package!(params[:package_name], :conan)
                        authorize_workhorse!(subject: project, maximum_size: project.actual_limits.conan_max_file_size)
                      end
                    end
                  end

                  desc 'Retrieve package references metadata by recipe revision' do
                    detail 'Retrieves the metadata for all package references associated with a specified recipe ' \
                      'revision. This feature was introduced in GitLab 18.1.'
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
                  route_setting :authorization, job_token_policies: :read_packages,
                    allow_public_access_for_enabled_project_features: :package_registry,
                    permissions: :read_conan_package, boundary_type: :project

                  get 'search', urgency: :low do
                    check_username_channel

                    authorize_read_package!(project)
                    not_found!('Package') unless package

                    references = package_references_for_recipe_revision

                    not_found!('Revision') unless references

                    references.pluck_reference_and_info.to_h
                  end

                  params do
                    requires :conan_package_reference, type: String,
                      regexp: Gitlab::Regex.conan_package_reference_regex, desc: 'Package reference',
                      documentation: { example: '5ab84d6acfe1f23c4fae0ab88f26e3a396351ac9' }
                  end
                  namespace 'packages/:conan_package_reference' do
                    namespace 'latest' do
                      desc 'Retrieve latest package revision' do
                        detail 'Retrieves the revision hash and creation date of the latest package revision for a ' \
                          'specified recipe revision and package reference. This feature was introduced in GitLab ' \
                          '17.11.'
                        success code: 200, model: ::API::Entities::Packages::Conan::Revision
                        failure [
                          { code: 400, message: 'Bad Request' },
                          { code: 401, message: 'Unauthorized' },
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
                        not_found!('Package') unless package

                        revision = latest_package_revision

                        not_found!('Revision') unless revision
                        present revision, with: ::API::Entities::Packages::Conan::Revision
                      end
                    end
                    namespace 'revisions' do
                      desc 'List all package revisions' do
                        detail 'Lists all package revisions for a specified recipe revision and package reference. ' \
                          'This feature was introduced in GitLab 18.0.'
                        success code: 200, model: ::API::Entities::Packages::Conan::PackageRevisions
                        failure [
                          { code: 400, message: 'Bad Request' },
                          { code: 401, message: 'Unauthorized' },
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
                        requires :package_revision, type: String, regexp: Gitlab::Regex.conan_revision_regex_combined,
                          desc: 'Package revision', documentation: { example: '3bdd2d8c8e76c876ebd1ac0469a4e72c' }
                      end
                      namespace ':package_revision' do
                        desc 'Delete a package revision' do
                          detail 'Deletes a specified package revision from the registry. If the package reference ' \
                            'has only one package revision, the package reference is deleted as well. ' \
                            'This feature was introduced in GitLab 18.1.'
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
                          permissions: :delete_conan_package, boundary_type: :project

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
                          desc 'List all package files' do
                            detail 'Lists all package files. This feature was introduced in GitLab 18.0.'
                            success code: 200, model: ::API::Entities::Packages::Conan::FilesList
                            failure [
                              { code: 400, message: 'Bad Request' },
                              { code: 401, message: 'Unauthorized' },
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
                            desc 'Retrieve a package file' do
                              detail 'Retrieves a specified package file from the package registry. This feature was ' \
                                'introduced in GitLab 17.11.'
                              success code: 200
                              failure [
                                { code: 400, message: 'Bad Request' },
                                { code: 401, message: 'Unauthorized' },
                                { code: 403, message: 'Forbidden' },
                                { code: 404, message: 'Not Found' }
                              ]
                              tags %w[packages_conan]
                            end
                            route_setting :authentication, job_token_allowed: true,
                              basic_auth_personal_access_token: true
                            route_setting :authorization, job_token_policies: :read_packages,
                              allow_public_access_for_enabled_project_features: :package_registry,
                              permissions: :read_conan_package, boundary_type: :project
                            get urgency: :low do
                              download_package_file(:package_file)
                            end

                            desc 'Upload a package file' do
                              detail 'Uploads a specified package file to the package registry. This feature was ' \
                                'introduced in GitLab 17.11.'
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

                            route_setting :authentication, job_token_allowed: true,
                              basic_auth_personal_access_token: true
                            route_setting :authorization, job_token_policies: :admin_packages,
                              permissions: :upload_conan_package, boundary_type: :project

                            put urgency: :low do
                              upload_package_file(:package_file)
                            end

                            desc 'Workhorse authorize the Conan package file' do
                              detail 'Authorizes the Conan package file. This feature was introduced in GitLab 17.11.'
                              success code: 200
                              failure [
                                { code: 400, message: 'Bad Request' },
                                { code: 401, message: 'Unauthorized' },
                                { code: 403, message: 'Forbidden' },
                                { code: 404, message: 'Not Found' }
                              ]
                              tags %w[packages_conan]
                            end

                            route_setting :authentication, job_token_allowed: true,
                              basic_auth_personal_access_token: true
                            route_setting :authorization, job_token_policies: :admin_packages,
                              skip_granular_token_authorization: :workhorse_pre_authorization

                            put 'authorize', urgency: :low do
                              protect_package!(params[:package_name], :conan)
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
