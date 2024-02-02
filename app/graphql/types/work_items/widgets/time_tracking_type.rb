# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      # rubocop:disable Graphql/AuthorizeTypes -- we already authorize the work item itself
      class TimeTrackingType < BaseObject
        graphql_name 'WorkItemWidgetTimeTracking'
        description 'Represents a time tracking widget'

        implements Types::WorkItems::WidgetInterface

        field :time_estimate, GraphQL::Types::Int,
          null: false,
          description: 'Time estimate of the work item.'
        field :total_time_spent, GraphQL::Types::Int,
          null: false,
          description: 'Total time (in seconds) reported as spent on the work item.'

        field :timelogs, Types::TimelogType.connection_type,
          null: false,
          description: 'Timelogs on the work item.'
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
