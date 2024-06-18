# frozen_string_literal: true

module Types
  module Ci
    module Catalog
      module Resources
        module Components
          # rubocop: disable Graphql/AuthorizeTypes -- Authorization handled by ComponentType -> VersionType
          class InputType < BaseObject
            graphql_name 'CiCatalogResourceComponentInput'

            field :default, GraphQL::Types::String, null: true, description: 'Default value for the input.'
            field :name, GraphQL::Types::String, null: true, description: 'Name of the input.'
            field :required, GraphQL::Types::Boolean, null: true, description: 'Indicates if an input is required.'
          end
          # rubocop: enable Graphql/AuthorizeTypes
        end
      end
    end
  end
end
