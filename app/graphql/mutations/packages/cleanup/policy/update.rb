# frozen_string_literal: true

module Mutations
  module Packages
    module Cleanup
      module Policy
        class Update < Mutations::BaseMutation
          graphql_name 'UpdatePackagesCleanupPolicy'

          include FindsProject

          authorize :admin_package

          argument :project_path,
            GraphQL::Types::ID,
            required: true,
            description: 'Project path where the packages cleanup policy is located.'

          argument :keep_n_duplicated_package_files,
            Types::Packages::Cleanup::KeepDuplicatedPackageFilesEnum,
            required: false,
            description: copy_field_description(
              Types::Packages::Cleanup::PolicyType,
              :keep_n_duplicated_package_files
            )

          field :packages_cleanup_policy,
            Types::Packages::Cleanup::PolicyType,
            null: true,
            description: 'Packages cleanup policy after mutation.'

          def resolve(project_path:, **args)
            project = authorized_find!(project_path)

            result = ::Packages::Cleanup::UpdatePolicyService
              .new(project: project, current_user: current_user, params: args)
              .execute

            {
              packages_cleanup_policy: result.payload[:packages_cleanup_policy],
              errors: result.errors
            }
          end
        end
      end
    end
  end
end
