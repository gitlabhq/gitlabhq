# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      module TimeTracking
        class TimelogInputType < BaseInputObject
          graphql_name 'WorkItemWidgetTimeTrackingTimelogInput'

          argument :time_spent, GraphQL::Types::String,
            required: true,
            description: 'Amount of time spent in human readable format. For example: 1h 30m.'

          argument :spent_at, ::Types::TimeType,
            required: false,
            description: 'Timestamp of when the time tracked was spent at, ' \
              'if not provided would be set to current timestamp.'

          argument :summary, GraphQL::Types::String,
            required: false,
            description: 'Summary of how the time was spent.'
        end
      end
    end
  end
end
