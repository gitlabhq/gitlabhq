# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      module ErrorTracking
        # rubocop:disable Graphql/AuthorizeTypes -- we already authorize the work item itself
        class StackTraceContextType < BaseObject
          graphql_name 'WorkItemWidgetErrorTrackingStackTraceContext'
          description 'Represents details about a line of code of the stack trace'

          field :line_number, GraphQL::Types::Int,
            null: true,
            description: 'Line number of code.', method: :first

          field :line, GraphQL::Types::String,
            null: true,
            description: 'Line of code.', method: :last
        end
        # rubocop:enable Graphql/AuthorizeTypes
      end
    end
  end
end
