# frozen_string_literal: true

module Types
  module ErrorTracking
    class SentryDetailedErrorType < ::Types::BaseObject
      graphql_name 'SentryDetailedError'
      description 'A Sentry error'

      present_using SentryErrorPresenter

      authorize :read_sentry_issue

      field :count, GraphQL::Types::Int,
        null: false,
        description: 'Count of occurrences.'
      field :culprit, GraphQL::Types::String,
        null: false,
        description: 'Culprit of the error.'
      field :external_base_url, GraphQL::Types::String,
        null: false,
        description: 'External Base URL of the Sentry Instance.'
      field :external_url, GraphQL::Types::String,
        null: false,
        description: 'External URL of the error.'
      field :first_release_last_commit, GraphQL::Types::String,
        null: true,
        description: 'Commit the error was first seen.'
      field :first_release_short_version, GraphQL::Types::String,
        null: true,
        description: 'Release short version the error was first seen.'
      field :first_release_version, GraphQL::Types::String,
        null: true,
        description: 'Release version the error was first seen.'
      field :first_seen, Types::TimeType,
        null: false,
        description: 'Timestamp when the error was first seen.'
      field :frequency, [Types::ErrorTracking::SentryErrorFrequencyType],
        null: false,
        description: 'Last 24hr stats of the error.'
      field :gitlab_commit, GraphQL::Types::String,
        null: true,
        description: 'GitLab commit SHA attributed to the Error based on the release version.'
      field :gitlab_commit_path, GraphQL::Types::String,
        null: true,
        description: 'Path to the GitLab page for the GitLab commit attributed to the error.'
      field :gitlab_issue_path, GraphQL::Types::String,
        method: :gitlab_issue,
        null: true,
        description: 'URL of GitLab Issue.'
      field :id, GraphQL::Types::ID,
        null: false,
        description: 'ID (global ID) of the error.'
      field :integrated, GraphQL::Types::Boolean,
        null: true,
        description: 'Error tracking backend.'
      field :last_release_last_commit, GraphQL::Types::String,
        null: true,
        description: 'Commit the error was last seen.'
      field :last_release_short_version, GraphQL::Types::String,
        null: true,
        description: 'Release short version the error was last seen.'
      field :last_release_version, GraphQL::Types::String,
        null: true,
        description: 'Release version the error was last seen.'
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
      field :tags, Types::ErrorTracking::SentryErrorTagsType,
        null: false,
        description: 'Tags associated with the Sentry Error.'
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
  end
end
