# frozen_string_literal: true

module Types
  module Namespaces
    module UserLevelPermissions
      class UserNamespaceUserLevelPermissionsType < BaseObject # rubocop:disable Graphql/AuthorizeTypes -- parent is already authorized
        graphql_name 'UserNamespaceUserLevelPermissions'
        implements ::Types::Namespaces::UserLevelPermissions
      end
    end
  end
end

::Types::Namespaces::UserLevelPermissions::UserNamespaceUserLevelPermissionsType.prepend_mod
