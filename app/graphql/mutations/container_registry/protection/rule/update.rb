# frozen_string_literal: true

module Mutations
  module ContainerRegistry
    module Protection
      module Rule
        class Update < ::Mutations::BaseMutation
          graphql_name 'UpdateContainerProtectionRepositoryRule'
          description 'Updates a container repository protection rule that controls ' \
            'who can modify container images based on user roles.'

          authorize :admin_container_image

          argument :id,
            ::Types::GlobalIDType[::ContainerRegistry::Protection::Rule],
            required: true,
            description: 'Global ID of the container repository protection rule to be updated.'

          argument :repository_path_pattern,
            GraphQL::Types::String,
            required: false,
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

          def resolve(id:, **kwargs)
            container_registry_protection_rule = authorized_find!(id: id)

            response = ::ContainerRegistry::Protection::UpdateRuleService.new(container_registry_protection_rule,
              current_user: current_user, params: kwargs).execute

            { container_protection_repository_rule: response.payload[:container_registry_protection_rule],
              errors: response.errors }
          end
        end
      end
    end
  end
end
