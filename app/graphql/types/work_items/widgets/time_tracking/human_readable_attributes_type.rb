# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      module TimeTracking
        # rubocop:disable Graphql/AuthorizeTypes -- we already authorize the work item itself
        class HumanReadableAttributesType < BaseObject
          graphql_name 'WorkItemWidgetTimeTrackingHumanReadableAttributes'
          description 'Represents a time tracking human readable attributes'

          field :time_estimate, GraphQL::Types::String,
            null: true, method: :human_time_estimate,
            description: 'Human-readable time estimate of the work item.'
          field :total_time_spent, GraphQL::Types::String,
            null: true, method: :human_total_time_spent,
            description: 'Human-readable total time reported as spent on the work item.'
        end
        # rubocop:enable Graphql/AuthorizeTypes
      end
    end
  end
end
