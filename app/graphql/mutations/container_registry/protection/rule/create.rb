# frozen_string_literal: true

module Mutations
  module ContainerRegistry
    module Protection
      module Rule
        class Create < ::Mutations::BaseMutation
          graphql_name 'CreateContainerProtectionRepositoryRule'
          description 'Creates a repository protection rule to restrict access to a project\'s container registry.'
          include FindsProject

          authorize :admin_container_image

          argument :project_path,
            GraphQL::Types::ID,
            required: true,
            description: 'Full path of the project where a protection rule is located.'

          argument :repository_path_pattern,
            GraphQL::Types::String,
            required: true,
            validates: { allow_blank: false },
            description: copy_field_description(
              Types::ContainerRegistry::Protection::RuleType,
              :repository_path_pattern
            )

          argument :minimum_access_level_for_delete,
            Types::ContainerRegistry::Protection::RuleAccessLevelEnum,
            required: false,
            description: copy_field_description(
              Types::ContainerRegistry::Protection::RuleType,
              :minimum_access_level_for_delete
            )

          argument :minimum_access_level_for_push,
            Types::ContainerRegistry::Protection::RuleAccessLevelEnum,
            required: false,
            description: copy_field_description(
              Types::ContainerRegistry::Protection::RuleType,
              :minimum_access_level_for_push
            )

          field :container_protection_repository_rule,
            Types::ContainerRegistry::Protection::RuleType,
            null: true,
            description: 'Container repository protection rule after mutation.'

          def resolve(project_path:, **kwargs)
            project = authorized_find!(project_path)

            response =
              ::ContainerRegistry::Protection::CreateRuleService
                .new(project: project, current_user: current_user, params: kwargs)
                .execute

            { container_protection_repository_rule: response.payload[:container_registry_protection_rule],
              errors: response.errors }
          end
        end
      end
    end
  end
end
