# frozen_string_literal: true

module Types
  module Ci
    module Catalog
      # rubocop: disable Graphql/AuthorizeTypes
      class ResourceType < BaseObject
        graphql_name 'CiCatalogResource'

        connection_type_class(Types::CountableConnectionType)

        field :id, GraphQL::Types::ID, null: false, description: 'ID of the catalog resource.',
          alpha: { milestone: '15.11' }

        field :name, GraphQL::Types::String, null: true, description: 'Name of the catalog resource.',
          alpha: { milestone: '15.11' }

        field :description, GraphQL::Types::String, null: true, description: 'Description of the catalog resource.',
          alpha: { milestone: '15.11' }

        field :icon, GraphQL::Types::String, null: true, description: 'Icon for the catalog resource.',
          method: :avatar_path, alpha: { milestone: '15.11' }
      end
      # rubocop: enable Graphql/AuthorizeTypes
    end
  end
end
