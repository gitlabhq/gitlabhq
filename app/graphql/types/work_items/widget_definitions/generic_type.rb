# frozen_string_literal: true

module Types
  module WorkItems
    module WidgetDefinitions
      # rubocop:disable Graphql/AuthorizeTypes -- Authorization too granular, parent type is authorized
      class GenericType < BaseObject
        graphql_name 'WorkItemWidgetDefinitionGeneric'
        description 'Represents a generic widget definition'

        implements ::Types::WorkItems::WidgetDefinitionInterface
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
