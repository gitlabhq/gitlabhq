# frozen_string_literal: true

module Types
  module Authz
    module AccessTokens
      # rubocop:disable Graphql/AuthorizeTypes -- Authorization handled in the resolver
      class GranularScopeType < BaseObject
        graphql_name 'AccessTokenGranularScope'
        description 'Granular scope applied to an access token.'

        field :access,
          Types::Authz::AccessTokens::GranularScopeAccessEnum,
          null: false,
          description: 'Access configured on a granular scope.'

        field :namespace,
          Types::NamespaceType,
          null: true,
          description: 'Namespace of the granular scope.'

        field :permissions,
          [Types::Authz::AccessTokens::PermissionType],
          null: true,
          description: 'List of permissions of a granular scope.'

        def access
          'personal_projects'
        end

        def permissions
          object.permissions.filter_map { |permission_name| ::Authz::Permission.get(permission_name) }
        end
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
