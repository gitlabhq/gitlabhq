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

        field :category,
          GraphQL::Types::String,
          null: false,
          description: 'Permission category.',
          method: :feature_category

        field :boundaries,
          [Types::Authz::AccessTokens::BoundaryEnum],
          null: true,
          description: 'List of resource types that the permission can be applied to.'
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
