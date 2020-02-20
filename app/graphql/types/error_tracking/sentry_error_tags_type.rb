# frozen_string_literal: true

module Types
  module ErrorTracking
    # rubocop: disable Graphql/AuthorizeTypes
    class SentryErrorTagsType < ::Types::BaseObject
      graphql_name 'SentryErrorTags'
      description 'State of a Sentry error'

      field :level, GraphQL::STRING_TYPE,
        null: true,
        description: "Severity level of the Sentry Error"
      field :logger, GraphQL::STRING_TYPE,
        null: true,
        description: "Logger of the Sentry Error"
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
