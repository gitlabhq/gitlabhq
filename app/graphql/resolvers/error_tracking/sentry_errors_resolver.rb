# frozen_string_literal: true

module Resolvers
  module ErrorTracking
    class SentryErrorsResolver < BaseResolver
      type Types::ErrorTracking::SentryErrorType.connection_type, null: true
      extension Gitlab::Graphql::Extensions::ExternallyPaginatedArrayExtension

      argument :search_term, ::GraphQL::Types::String,
              description: 'Search query for the Sentry error details.',
              required: false

      # TODO: convert to Enum
      argument :sort, ::GraphQL::Types::String,
              description: 'Attribute to sort on. Options are frequency, first_seen, last_seen. last_seen is default.',
              required: false

      delegate :project, to: :object

      def resolve(**args)
        args[:cursor] = args.delete(:after)

        result = ::ErrorTracking::ListIssuesService.new(project, current_user, args).execute

        next_cursor = result.dig(:pagination, 'next', 'cursor')
        previous_cursor = result.dig(:pagination, 'previous', 'cursor')
        issues = result[:issues]

        # ReactiveCache is still fetching data
        return if issues.nil?

        Gitlab::Graphql::ExternallyPaginatedArray.new(previous_cursor, next_cursor, *issues)
      end

      def self.field_options
        super.merge(connection: false) # we manage the pagination manually, so opt out of the connection field extension
      end
    end
  end
end
