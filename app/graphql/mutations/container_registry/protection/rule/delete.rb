# frozen_string_literal: true

module Mutations
  module ContainerRegistry
    module Protection
      module Rule
        class Delete < ::Mutations::BaseMutation
          graphql_name 'DeleteContainerProtectionRepositoryRule'
          description 'Deletes a container registry protection rule. ' \
            'Available only when feature flag `container_registry_protected_containers` is enabled.'

          authorize :admin_container_image

          argument :id,
            ::Types::GlobalIDType[::ContainerRegistry::Protection::Rule],
            required: true,
            description: 'Global ID of the container registry protection rule to delete.'

          field :container_protection_repository_rule,
            Types::ContainerRegistry::Protection::RuleType,
            null: true,
            experiment: { milestone: '16.7' },
            description: 'Container registry protection rule that was deleted successfully.'

          def resolve(id:, **_kwargs)
            container_registry_protection_rule = authorized_find!(id: id)
            project = container_registry_protection_rule.project

            if Feature.disabled?(:container_registry_protected_containers, project.root_ancestor)
              raise_resource_not_available_error!("'container_registry_protected_containers' feature flag is disabled")
            end

            response = ::ContainerRegistry::Protection::DeleteRuleService.new(container_registry_protection_rule,
              current_user: current_user).execute

            { container_protection_repository_rule: response.payload[:container_registry_protection_rule],
              errors: response.errors }
          end
        end
      end
    end
  end
end
