# frozen_string_literal: true

module Types
  module ErrorTracking
    class SentryErrorCollectionType < ::Types::BaseObject
      graphql_name 'SentryErrorCollection'
      description 'An object containing a collection of Sentry errors, and a detailed error.'

      authorize :read_sentry_issue

      field :errors,
            Types::ErrorTracking::SentryErrorType.connection_type,
            connection: false,
            null: true,
            description: "Collection of Sentry Errors",
            extensions: [Gitlab::Graphql::Extensions::ExternallyPaginatedArrayExtension],
            resolver: Resolvers::ErrorTracking::SentryErrorsResolver do
              argument :search_term,
                      String,
                      description: 'Search query for the Sentry error details',
                      required: false
              argument :sort,
                      String,
                      description: 'Attribute to sort on. Options are frequency, first_seen, last_seen. last_seen is default.',
                      required: false
            end
      field :detailed_error, Types::ErrorTracking::SentryDetailedErrorType,
            null: true,
            description: 'Detailed version of a Sentry error on the project',
            resolver: Resolvers::ErrorTracking::SentryDetailedErrorResolver
      field :error_stack_trace, Types::ErrorTracking::SentryErrorStackTraceType,
            null: true,
            description: 'Stack Trace of Sentry Error',
            resolver: Resolvers::ErrorTracking::SentryErrorStackTraceResolver
      field :external_url,
            GraphQL::STRING_TYPE,
            null: true,
            description: "External URL for Sentry"
    end
  end
end
