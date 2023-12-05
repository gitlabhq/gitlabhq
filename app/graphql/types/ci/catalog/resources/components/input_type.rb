# frozen_string_literal: true

module Types
  module Ci
    module Catalog
      module Resources
        module Components
          # rubocop: disable Graphql/AuthorizeTypes -- Authorization hanlded by ComponentType -> VersionType
          class InputType < BaseObject
            graphql_name 'CiCatalogResourcesComponentsInput'

            field :name, GraphQL::Types::String, null: true,
              description: 'Name of the input.',
              alpha: { milestone: '16.7' }

            field :default, GraphQL::Types::String, null: true,
              description: 'Default value for the input.',
              alpha: { milestone: '16.7' }

            field :required, GraphQL::Types::Boolean, null: true,
              description: 'Indicates if an input is required.',
              alpha: { milestone: '16.7' }
          end
        end
      end
      # rubocop: enable Graphql/AuthorizeTypes
    end
  end
end
