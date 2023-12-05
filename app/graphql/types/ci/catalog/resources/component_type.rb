# frozen_string_literal: true

module Types
  module Ci
    module Catalog
      module Resources
        # rubocop: disable Graphql/AuthorizeTypes -- Authorization is handled by VersionsType
        class ComponentType < BaseObject
          graphql_name 'CiCatalogResourcesComponent'

          field :id, ::Types::GlobalIDType[::Ci::Catalog::Resources::Component], null: false,
            description: 'ID of the component.',
            alpha: { milestone: '16.7' }

          field :name, GraphQL::Types::String, null: true,
            description: 'Name of the component.',
            alpha: { milestone: '16.7' }

          field :path, GraphQL::Types::String, null: true,
            description: 'Path used to include the component.',
            alpha: { milestone: '16.7' }

          field :inputs, [Types::Ci::Catalog::Resources::Components::InputType], null: true,
            description: 'Inputs for the component.',
            alpha: { milestone: '16.7' }

          def inputs
            object.inputs.map do |key, value|
              {
                name: key,
                required: !value&.key?('default'),
                default: value&.dig('default')
              }
            end
          end
        end
      end
      # rubocop: enable Graphql/AuthorizeTypes
    end
  end
end
