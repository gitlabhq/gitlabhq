# frozen_string_literal: true

module Mutations
  module ContainerRegistry
    module Protection
      module TagRule
        class Delete < ::Mutations::BaseMutation
          graphql_name 'DeleteContainerProtectionTagRule'
          description 'Deletes a protection rule that controls which user ' \
            'roles can modify container image tags matching a specified pattern.'

          authorize :destroy_container_registry_protection_tag_rule

          argument :id,
            ::Types::GlobalIDType[::ContainerRegistry::Protection::TagRule],
            required: true,
            description: 'Global ID of the tag protection rule to delete.'

          field :container_protection_tag_rule,
            Types::ContainerRegistry::Protection::TagRuleType,
            null: true,
            experiment: { milestone: '17.8' },
            description: 'Deleted protection rule for container image tags.'

          def resolve(id:, **_kwargs)
            container_protection_tag_rule = authorized_find!(id:)

            response = ::ContainerRegistry::Protection::DeleteTagRuleService.new(container_protection_tag_rule,
              current_user: current_user).execute

            { container_protection_tag_rule: response[:container_protection_tag_rule],
              errors: response.errors }
          end
        end
      end
    end
  end
end
