# frozen_string_literal: true

module Types
  module Authz
    module AccessTokens
      # rubocop:disable Graphql/AuthorizeTypes -- Authorization handled in the resolver
      class PermissionType < BaseObject
        graphql_name 'AccessTokenPermission'

        description 'Permission that belongs to a granular scope.'

        field :name,
          GraphQL::Types::String,
          null: false,
          description: 'Name of the permission.'

        field :description,
          GraphQL::Types::String,
          null: false,
          description: 'Description of the permission.'

        field :action,
          GraphQL::Types::String,
          null: false,
          description: 'Action of the permission.'

        field :resource,
          GraphQL::Types::String,
          null: false,
          description: 'Resource of the permission.'
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
