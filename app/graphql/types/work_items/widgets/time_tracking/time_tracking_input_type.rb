# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      module TimeTracking
        class TimeTrackingInputType < BaseInputObject
          graphql_name 'WorkItemWidgetTimeTrackingInput'

          argument :time_estimate, GraphQL::Types::String,
            required: false,
            description: 'Time estimate for the work item in human readable format. For example: 1h 30m.'

          argument :timelog, ::Types::WorkItems::Widgets::TimeTracking::TimelogInputType,
            required: false,
            description: 'Timelog data for time spent on the work item.'
        end
      end
    end
  end
end
