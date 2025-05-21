# frozen_string_literal: true

module Types
  module Namespaces
    module UserLevelPermissions
      class GroupNamespaceUserLevelPermissionsType < BaseObject # rubocop:disable Graphql/AuthorizeTypes -- parent is already authorized
        graphql_name 'GroupNamespaceUserLevelPermissions'
        implements ::Types::Namespaces::UserLevelPermissions

        alias_method :group, :object

        def can_admin_label
          can?(current_user, :admin_label, group)
        end

        def can_create_projects
          can?(current_user, :create_projects, group)
        end
      end
    end
  end
end

::Types::Namespaces::UserLevelPermissions::GroupNamespaceUserLevelPermissionsType.prepend_mod
