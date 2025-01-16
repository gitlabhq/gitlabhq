# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      class StartAndDueDateUpdateInputType < BaseInputObject
        graphql_name 'WorkItemWidgetStartAndDueDateUpdateInput'

        argument :due_date,
          ::Types::DateType,
          required: false,
          description: 'Due date for the work item.'

        argument :start_date,
          ::Types::DateType,
          required: false,
          description: 'Start date for the work item.'
      end
    end
  end
end
Types::WorkItems::Widgets::StartAndDueDateUpdateInputType.prepend_mod
