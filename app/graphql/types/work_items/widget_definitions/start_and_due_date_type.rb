# frozen_string_literal: true

module Types
  module WorkItems
    module WidgetDefinitions
      # rubocop:disable Graphql/AuthorizeTypes -- Authorization too granular, parent type is authorized
      class StartAndDueDateType < BaseObject
        graphql_name 'WorkItemWidgetDefinitionStartAndDueDate'
        description 'Represents a start and due date widget definition'

        implements ::Types::WorkItems::WidgetDefinitionInterface

        field :can_roll_up, GraphQL::Types::Boolean,
          null: true,
          description: 'Indicates whether the start and due date widget should roll up dates.',
          experiment: { milestone: '18.8' }

        def can_roll_up
          object.widget_options&.dig(object.widget_type.to_sym, :can_roll_up)
        end
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
