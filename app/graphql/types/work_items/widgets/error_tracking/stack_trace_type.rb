# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      module ErrorTracking
        # Disabling widget level authorization as it might be too granular
        # and we already authorize the parent work item
        # rubocop:disable Graphql/AuthorizeTypes -- reason above
        class StackTraceType < BaseObject
          graphql_name 'ErrorTrackingStackTrace'
          description 'Represents a stack trace'

          connection_type_class Types::CountableConnectionType

          field :filename, GraphQL::Types::String,
            null: true,
            description: 'Filename of the stack trace.'

          field :absolute_path, GraphQL::Types::String,
            null: true,
            description: 'Absolute path of the stack trace.', hash_key: "absPath"

          field :function, GraphQL::Types::String,
            null: true,
            description: 'Name of the function where the error occured.'

          field :line_number, GraphQL::Types::Int,
            null: true,
            description: 'Line number of the stack trace.', hash_key: "lineNo"

          field :column_number, GraphQL::Types::Int,
            null: true,
            description: 'Column number of the stack trace.', hash_key: "colNo"

          field :context, [Types::WorkItems::Widgets::ErrorTracking::StackTraceContextType],
            null: true,
            description: 'Context of the stack trace.', hash_key: "context"
        end
        # rubocop:enable Graphql/AuthorizeTypes
      end
    end
  end
end
