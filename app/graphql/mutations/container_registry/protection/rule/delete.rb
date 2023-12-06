# frozen_string_literal: true

module Mutations
  module ContainerRegistry
    module Protection
      module Rule
        class Delete < ::Mutations::BaseMutation
          graphql_name 'DeleteContainerRegistryProtectionRule'
          description 'Deletes a container registry protection rule. ' \
                      'Available only when feature flag `container_registry_protected_containers` is enabled.'

          authorize :admin_container_image

          argument :id,
            ::Types::GlobalIDType[::ContainerRegistry::Protection::Rule],
            required: true,
            description: 'Global ID of the container registry protection rule to delete.'

          field :container_registry_protection_rule,
            Types::ContainerRegistry::Protection::RuleType,
            null: true,
            description: 'Container registry protection rule that was deleted successfully.'

          def resolve(id:, **_kwargs)
            if Feature.disabled?(:container_registry_protected_containers)
              raise_resource_not_available_error!("'container_registry_protected_containers' feature flag is disabled")
            end

            container_registry_protection_rule = authorized_find!(id: id)

            response = ::ContainerRegistry::Protection::DeleteRuleService.new(container_registry_protection_rule,
              current_user: current_user).execute

            { container_registry_protection_rule: response.payload[:container_registry_protection_rule],
              errors: response.errors }
          end
        end
      end
    end
  end
end
