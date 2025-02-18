# frozen_string_literal: true

module Mutations
  module ContainerRegistry
    module Protection
      module TagRule
        class Create < ::Mutations::BaseMutation
          graphql_name 'createContainerProtectionTagRule'
          description 'Creates a protection rule to control which user roles ' \
            'can modify container image tags matching a specified pattern. ' \
            'Available only when feature flag `container_registry_protected_tags` is enabled.'

          include FindsProject

          authorize :admin_container_image

          argument :project_path,
            GraphQL::Types::ID,
            required: true,
            description: 'Full path of the project containing the container image tags.'

          argument :tag_name_pattern,
            GraphQL::Types::String,
            required: true,
            validates: { allow_blank: false },
            description: copy_field_description(
              Types::ContainerRegistry::Protection::TagRuleType,
              :tag_name_pattern
            )

          argument :minimum_access_level_for_delete,
            Types::ContainerRegistry::Protection::TagRuleAccessLevelEnum,
            required: false,
            description: copy_field_description(
              Types::ContainerRegistry::Protection::TagRuleType,
              :minimum_access_level_for_delete
            )

          argument :minimum_access_level_for_push,
            Types::ContainerRegistry::Protection::TagRuleAccessLevelEnum,
            required: false,
            description: copy_field_description(
              Types::ContainerRegistry::Protection::TagRuleType,
              :minimum_access_level_for_push
            )

          field :container_protection_tag_rule,
            Types::ContainerRegistry::Protection::TagRuleType,
            null: true,
            experiment: { milestone: '17.8' },
            description: 'Protection rule for container image tags after creation.'

          def resolve(project_path:, **kwargs)
            project = authorized_find!(project_path)

            if Feature.disabled?(:container_registry_protected_tags, project)
              raise_resource_not_available_error!("'container_registry_protected_tags' feature flag is disabled")
            end

            response =
              ::ContainerRegistry::Protection::CreateTagRuleService
                .new(project: project, current_user: current_user, params: kwargs)
                .execute

            { container_protection_tag_rule: response[:container_protection_tag_rule],
              errors: response.errors }
          end
        end
      end
    end
  end
end
