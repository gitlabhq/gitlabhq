# frozen_string_literal: true

module Types
  module Namespaces
    module UserLevelPermissions
      include ::Types::BaseInterface
      include ::IssuablesHelper

      graphql_name 'UserLevelPermissions'

      # rubocop:disable Layout/LineLength -- Expected file length
      TYPE_MAPPINGS = {
        ::Group => ::Types::Namespaces::UserLevelPermissions::GroupNamespaceUserLevelPermissionsType,
        ::Namespaces::ProjectNamespace => ::Types::Namespaces::UserLevelPermissions::ProjectNamespaceUserLevelPermissionsType,
        ::Namespaces::UserNamespace => ::Types::Namespaces::UserLevelPermissions::UserNamespaceUserLevelPermissionsType
      }.freeze
      # rubocop:enable Layout/LineLength

      field :can_admin_label,
        GraphQL::Types::Boolean,
        null: true,
        description: 'Whether the current user can admin labels in the namespace.',
        fallback_value: false

      field :can_create_projects,
        GraphQL::Types::Boolean,
        null: true,
        description: 'Whether the current user can create projects in the namespace.',
        fallback_value: false

      def self.type_mappings
        TYPE_MAPPINGS
      end

      def self.resolve_type(object, _context)
        type_mappings[object.class] || raise("Unknown GraphQL type for namespace type #{object.class}")
      end

      orphan_types(*type_mappings.values)
    end
  end
end

::Types::Namespaces::UserLevelPermissions.prepend_mod
