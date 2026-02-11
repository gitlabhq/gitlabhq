# frozen_string_literal: true

module Types
  module Ci
    module Catalog
      module Resources
        # rubocop: disable Graphql/AuthorizeTypes -- Parent type handles authorization
        class SemverType < BaseObject
          graphql_name 'CiCatalogResourceSemver'
          description 'Semantic version information for a catalog resource version'

          field :major, GraphQL::Types::Int, null: true,
            description: 'Major version number.'

          field :minor, GraphQL::Types::Int, null: true,
            description: 'Minor version number.'

          field :patch, GraphQL::Types::Int, null: true,
            description: 'Patch version number.'
        end
        # rubocop: enable Graphql/AuthorizeTypes
      end
    end
  end
end
