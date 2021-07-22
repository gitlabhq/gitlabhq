# frozen_string_literal: true

module Types
  module ErrorTracking
    # rubocop: disable Graphql/AuthorizeTypes
    class SentryErrorStackTraceContextType < ::Types::BaseObject
      graphql_name 'SentryErrorStackTraceContext'
      description 'An object context for a Sentry error stack trace'

      field :line,
            GraphQL::Types::Int,
            null: false,
            description: 'Line number of the context.'
      field :code,
            GraphQL::Types::String,
            null: false,
            description: 'Code number of the context.'

      def line
        object[0]
      end

      def code
        object[1]
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
