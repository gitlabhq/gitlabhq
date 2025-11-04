# frozen_string_literal: true

module Types
  module Authz
    module AccessTokens
      # rubocop:disable Graphql/AuthorizeTypes -- Authorization handled in the resolver
      class PermissionType < BaseObject
        graphql_name 'AccessTokenPermission'

        description 'A permission added to a fine-grained access token'

        field :name,
          GraphQL::Types::String,
          null: false,
          description: 'Permission name.'

        field :description,
          GraphQL::Types::String,
          null: false,
          description: 'Permission description.'

        field :action,
          GraphQL::Types::String,
          null: false,
          description: 'Permission action.'

        field :resource,
          GraphQL::Types::String,
          null: false,
          description: 'Permission resource.'
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
