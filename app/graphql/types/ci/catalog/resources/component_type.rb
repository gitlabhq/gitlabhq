# frozen_string_literal: true

module Types
  module Ci
    module Catalog
      module Resources
        # rubocop: disable Graphql/AuthorizeTypes -- Authorization is handled by VersionType
        class ComponentType < BaseObject
          graphql_name 'CiCatalogResourceComponent'

          field :id, ::Types::GlobalIDType[::Ci::Catalog::Resources::Component], null: false,
            description: 'ID of the component.'

          field :name, GraphQL::Types::String, null: true,
            description: 'Name of the component.'

          field :include_path, GraphQL::Types::String, null: true,
            description: 'Path used to include the component.'

          field :inputs, [Types::Ci::Inputs::SpecType], null: true,
            description: 'Inputs for the component.'

          field :last_30_day_usage_count, GraphQL::Types::Int, null: true,
            description: 'Number of times the component has been used in the last 30 days ' \
              'in a pipeline using `include`.'

          def inputs
            object.spec.fetch('inputs', {}).map do |key, value|
              {
                name: key,
                required?: !value&.key?('default'),
                default: value&.dig('default'),
                description: value&.dig('description'),
                regex: value&.dig('regex'),
                type: value&.dig('type') || 'string'
              }
            end
          end
        end
      end
      # rubocop: enable Graphql/AuthorizeTypes
    end
  end
end
