# frozen_string_literal: true

module Types
  module PermissionTypes
    module ContainerRegistry
      module Protection
        class TagRule < BasePermissionType
          graphql_name 'ContainerRegistryProtectionTagRulePermissions'

          ability_field :destroy_container_registry_protection_tag_rule
        end
      end
    end
  end
end
