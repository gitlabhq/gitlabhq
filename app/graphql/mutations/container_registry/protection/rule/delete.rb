# frozen_string_literal: true

module Mutations
  module ContainerRegistry
    module Protection
      module Rule
        class Delete < ::Mutations::BaseMutation
          graphql_name 'DeleteContainerProtectionRepositoryRule'
          description 'Deletes a container repository protection rule.'

          authorize :admin_container_image

          argument :id,
            ::Types::GlobalIDType[::ContainerRegistry::Protection::Rule],
            required: true,
            description: 'Global ID of the container repository protection rule to delete.'

          field :container_protection_repository_rule,
            Types::ContainerRegistry::Protection::RuleType,
            null: true,
            description: 'Container repository protection rule that was deleted successfully.'

          def resolve(id:, **_kwargs)
            container_registry_protection_rule = authorized_find!(id: id)

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
