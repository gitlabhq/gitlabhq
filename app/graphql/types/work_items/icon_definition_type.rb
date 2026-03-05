# frozen_string_literal: true

# rubocop:disable Graphql/AuthorizeTypes -- static data, no authorization needed
module Types
  module WorkItems
    class IconDefinitionType < ::Types::BaseObject
      graphql_name 'WorkItemTypeIconDefinition'
      description 'Represents an available icon for work item types.'

      field :name, GraphQL::Types::String,
        null: false,
        description: 'Name of the icon.'

      field :label, GraphQL::Types::String,
        null: false,
        description: 'Human-readable screen reader label for the icon.'
    end
  end
end
# rubocop:enable Graphql/AuthorizeTypes
