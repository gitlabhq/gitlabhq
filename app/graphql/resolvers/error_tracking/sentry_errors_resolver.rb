# frozen_string_literal: true

module Resolvers
  module ErrorTracking
    class SentryErrorsResolver < BaseResolver
      type Types::ErrorTracking::SentryErrorType.connection_type, null: true

      def resolve(**args)
        args[:cursor] = args.delete(:after)
        project = object.project

        result = ::ErrorTracking::ListIssuesService.new(
          project,
          context[:current_user],
          args
        ).execute

        next_cursor = result[:pagination]&.dig('next', 'cursor')
        previous_cursor = result[:pagination]&.dig('previous', 'cursor')
        issues = result[:issues]

        # ReactiveCache is still fetching data
        return if issues.nil?

        Gitlab::Graphql::ExternallyPaginatedArray.new(previous_cursor, next_cursor, *issues)
      end
    end
  end
end
