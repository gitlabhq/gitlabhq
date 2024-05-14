# frozen_string_literal: true

module Types
  module ErrorTracking
    # rubocop: disable Graphql/AuthorizeTypes
    class SentryErrorType < ::Types::BaseObject
      graphql_name 'SentryError'
      description 'A Sentry error. A simplified version of SentryDetailedError'

      present_using SentryErrorPresenter

      field :count, GraphQL::Types::Int,
        null: false,
        description: 'Count of occurrences.'
      field :culprit, GraphQL::Types::String,
        null: false,
        description: 'Culprit of the error.'
      field :external_url, GraphQL::Types::String,
        null: false,
        description: 'External URL of the error.'
      field :first_seen, Types::TimeType,
        null: false,
        description: 'Timestamp when the error was first seen.'
      field :frequency, [Types::ErrorTracking::SentryErrorFrequencyType],
        null: false,
        description: 'Last 24hr stats of the error.'
      field :id, GraphQL::Types::ID,
        null: false,
        description: 'ID (global ID) of the error.'
      field :last_seen, Types::TimeType,
        null: false,
        description: 'Timestamp when the error was last seen.'
      field :message, GraphQL::Types::String,
        null: true,
        description: 'Sentry metadata message of the error.'
      field :sentry_id, GraphQL::Types::String,
        method: :id,
        null: false,
        description: 'ID (Sentry ID) of the error.'
      field :sentry_project_id, GraphQL::Types::ID,
        method: :project_id,
        null: false,
        description: 'ID of the project (Sentry project).'
      field :sentry_project_name, GraphQL::Types::String,
        method: :project_name,
        null: false,
        description: 'Name of the project affected by the error.'
      field :sentry_project_slug, GraphQL::Types::String,
        method: :project_slug,
        null: false,
        description: 'Slug of the project affected by the error.'
      field :short_id, GraphQL::Types::String,
        null: false,
        description: 'Short ID (Sentry ID) of the error.'
      field :status, Types::ErrorTracking::SentryErrorStatusEnum,
        null: false,
        description: 'Status of the error.'
      field :title, GraphQL::Types::String,
        null: false,
        description: 'Title of the error.'
      field :type, GraphQL::Types::String,
        null: false,
        description: 'Type of the error.'
      field :user_count, GraphQL::Types::Int,
        null: false,
        description: 'Count of users affected by the error.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
