# frozen_string_literal: true

module Types
  module ErrorTracking
    # rubocop: disable Graphql/AuthorizeTypes
    class SentryErrorStackTraceEntryType < ::Types::BaseObject
      graphql_name 'SentryErrorStackTraceEntry'
      description 'An object containing a stack trace entry for a Sentry error'

      field :col, GraphQL::Types::String,
        null: true,
        description: 'Function in which the Sentry error occurred.', hash_key: "colNo"
      field :file_name, GraphQL::Types::String,
        null: true,
        description: 'File in which the Sentry error occurred.', hash_key: "filename"
      field :function, GraphQL::Types::String,
        null: true,
        description: 'Function in which the Sentry error occurred.', hash_key: "function"
      field :line, GraphQL::Types::String,
        null: true,
        description: 'Function in which the Sentry error occurred.', hash_key: "lineNo"
      field :trace_context, [Types::ErrorTracking::SentryErrorStackTraceContextType],
        null: true,
        description: 'Context of the Sentry error.'

      def trace_context
        object['context']
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
