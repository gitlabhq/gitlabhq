# frozen_string_literal: true

module Types
  module Ci
    module Catalog
      module Resources
        module Components
          class InputType < BaseObject
            graphql_name 'CiCatalogResourceComponentInput'

            field :default, GraphQL::Types::String, null: true, description: 'Default value for the input.'
            field :description, GraphQL::Types::String, null: true, description: 'Description of the input.'
            field :name, GraphQL::Types::String, null: true, description: 'Name of the input.'

            field :regex, GraphQL::Types::String, null: true,
              description: 'Pattern that the input value must match. Only applicable to string inputs.'

            field :required, GraphQL::Types::Boolean, null: true, description: 'Indicates if an input is required.'

            field :type, Types::Ci::Catalog::Resources::Components::InputTypeEnum, null: true,
              description: 'Type of the input.'
          end
        end
      end
    end
  end
end
