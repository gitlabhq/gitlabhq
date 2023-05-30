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

        field :web_path, GraphQL::Types::String, null: true, description: 'Web path of the catalog resource.',
          alpha: { milestone: '16.1' }

        field :versions, Types::ReleaseType.connection_type, null: true,
          description: 'Versions of the catalog resource.',
          resolver: Resolvers::ReleasesResolver,
          alpha: { milestone: '16.1' }

        field :star_count, GraphQL::Types::Int, null: false,
          description: 'Number of times the catalog resource has been starred.',
          alpha: { milestone: '16.1' }

        field :forks_count, GraphQL::Types::Int, null: false, calls_gitaly: true,
          description: 'Number of times the catalog resource has been forked.',
          alpha: { milestone: '16.1' }

        def web_path
          ::Gitlab::Routing.url_helpers.project_path(object.project)
        end

        def forks_count
          BatchLoader::GraphQL.wrap(object.forks_count)
        end
      end
      # rubocop: enable Graphql/AuthorizeTypes
    end
  end
end
