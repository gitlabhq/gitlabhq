# frozen_string_literal: true

module Mutations
  module ContainerRegistry
    module Protection
      module TagRule
        class Update < ::Mutations::BaseMutation
          graphql_name 'UpdateContainerProtectionTagRule'
          description 'Updates a protection rule that controls which user roles ' \
            'can modify container image tags matching a specified pattern. ' \
            'Available only when feature flag `container_registry_protected_tags` is enabled.'

          authorize :admin_container_image

          argument :id,
            ::Types::GlobalIDType[::ContainerRegistry::Protection::TagRule],
            required: true,
            description: 'Global ID of the tag protection rule to update.'

          argument :tag_name_pattern,
            GraphQL::Types::String,
            required: false,
            validates: { allow_blank: false },
            experiment: { milestone: '17.8' },
            description: copy_field_description(
              Types::ContainerRegistry::Protection::TagRuleType,
              :tag_name_pattern
            )

          argument :minimum_access_level_for_delete,
            Types::ContainerRegistry::Protection::TagRuleAccessLevelEnum,
            required: false,
            experiment: { milestone: '17.8' },
            description: copy_field_description(
              Types::ContainerRegistry::Protection::TagRuleType,
              :minimum_access_level_for_delete
            )

          argument :minimum_access_level_for_push,
            Types::ContainerRegistry::Protection::TagRuleAccessLevelEnum,
            required: false,
            experiment: { milestone: '17.8' },
            description: copy_field_description(
              Types::ContainerRegistry::Protection::TagRuleType,
              :minimum_access_level_for_push
            )

          field :container_protection_tag_rule,
            Types::ContainerRegistry::Protection::TagRuleType,
            null: true,
            experiment: { milestone: '17.8' },
            description: 'Protection rule for container image tags after creation.'

          def resolve(id:, **kwargs)
            container_protection_tag_rule = authorized_find!(id:)

            if Feature.disabled?(:container_registry_protected_tags, container_protection_tag_rule.project)
              raise_resource_not_available_error!("'container_registry_protected_tags' feature flag is disabled")
            end

            response = ::ContainerRegistry::Protection::UpdateTagRuleService.new(container_protection_tag_rule,
              current_user: current_user, params: kwargs).execute

            { container_protection_tag_rule: response[:container_protection_tag_rule],
              errors: response.errors }
          end
        end
      end
    end
  end
end
