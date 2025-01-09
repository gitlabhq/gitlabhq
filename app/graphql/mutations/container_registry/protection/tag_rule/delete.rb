# frozen_string_literal: true

module Mutations
  module ContainerRegistry
    module Protection
      module TagRule
        class Delete < ::Mutations::BaseMutation
          graphql_name 'DeleteContainerProtectionTagRule'
          description 'Deletes a protection rule that controls which user ' \
            'roles can modify container image tags matching a specified pattern. ' \
            'Available only when feature flag `container_registry_protected_tags` is enabled.'

          authorize :admin_container_image

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

            if Feature.disabled?(:container_registry_protected_tags, container_protection_tag_rule.project)
              raise_resource_not_available_error!("'container_registry_protected_tags' feature flag is disabled")
            end

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
