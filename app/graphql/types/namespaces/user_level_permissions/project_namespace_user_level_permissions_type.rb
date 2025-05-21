# frozen_string_literal: true

module Types
  module Namespaces
    module UserLevelPermissions
      class ProjectNamespaceUserLevelPermissionsType < BaseObject # rubocop:disable Graphql/AuthorizeTypes -- parent is already authorized
        graphql_name 'ProjectNamespaceUserLevelPermissions'
        implements ::Types::Namespaces::UserLevelPermissions

        alias_method :project, :object

        def can_admin_label
          can?(current_user, :admin_label, project)
        end
      end
    end
  end
end

::Types::Namespaces::UserLevelPermissions::ProjectNamespaceUserLevelPermissionsType.prepend_mod
