# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      # rubocop:disable Graphql/AuthorizeTypes -- Disabling widget level authorization as it might be too granular
      # and we already authorize the parent work item
      class StartAndDueDateType < BaseObject
        graphql_name 'WorkItemWidgetStartAndDueDate'
        description 'Represents a start and due date widget'

        implements ::Types::WorkItems::WidgetInterface

        field :due_date,
          ::Types::DateType,
          null: true,
          description: 'Due date of the work item.'

        field :start_date,
          ::Types::DateType,
          null: true,
          description: 'Start date of the work item.'

        field :roll_up,
          ::GraphQL::Types::Boolean,
          method: :can_rollup?,
          null: false,
          description: 'Indicates if the work item can use rolled up dates.'
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
Types::WorkItems::Widgets::StartAndDueDateType.prepend_mod
