# frozen_string_literal: true

module Mutations
  module ContainerRegistry
    module Protection
      module Rule
        class Create < ::Mutations::BaseMutation
          graphql_name 'CreateContainerRegistryProtectionRule'
          description 'Creates a protection rule to restrict access to a project\'s container registry. ' \
                      'Available only when feature flag `container_registry_protected_containers` is enabled.'

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

          field :container_registry_protection_rule,
            Types::ContainerRegistry::Protection::RuleType,
            null: true,
            alpha: { milestone: '16.6' },
            description: 'Container registry protection rule after mutation.'

          def resolve(project_path:, **kwargs)
            project = authorized_find!(project_path)

            if Feature.disabled?(:container_registry_protected_containers, project)
              raise_resource_not_available_error!("'container_registry_protected_containers' feature flag is disabled")
            end

            response = ::ContainerRegistry::Protection::CreateRuleService.new(project, current_user, kwargs).execute

            { container_registry_protection_rule: response.payload[:container_registry_protection_rule],
              errors: response.errors }
          end
        end
      end
    end
  end
end
