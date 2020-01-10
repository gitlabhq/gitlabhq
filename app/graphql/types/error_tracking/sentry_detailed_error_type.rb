# frozen_string_literal: true

module Types
  module ErrorTracking
    class SentryDetailedErrorType < ::Types::BaseObject
      graphql_name 'SentryDetailedError'

      present_using SentryDetailedErrorPresenter

      authorize :read_sentry_issue

      field :id, GraphQL::ID_TYPE,
            null: false,
            description: "ID (global ID) of the error"
      field :sentry_id, GraphQL::STRING_TYPE,
            method: :id,
            null: false,
            description: "ID (Sentry ID) of the error"
      field :title, GraphQL::STRING_TYPE,
            null: false,
            description: "Title of the error"
      field :type, GraphQL::STRING_TYPE,
            null: false,
            description: "Type of the error"
      field :user_count, GraphQL::INT_TYPE,
            null: false,
            description: "Count of users affected by the error"
      field :count, GraphQL::INT_TYPE,
            null: false,
            description: "Count of occurrences"
      field :first_seen, Types::TimeType,
            null: false,
            description: "Timestamp when the error was first seen"
      field :last_seen, Types::TimeType,
            null: false,
            description: "Timestamp when the error was last seen"
      field :message, GraphQL::STRING_TYPE,
            null: true,
            description: "Sentry metadata message of the error"
      field :culprit, GraphQL::STRING_TYPE,
            null: false,
            description: "Culprit of the error"
      field :external_url, GraphQL::STRING_TYPE,
            null: false,
            description: "External URL of the error"
      field :sentry_project_id, GraphQL::ID_TYPE,
            method: :project_id,
            null: false,
            description: "ID of the project (Sentry project)"
      field :sentry_project_name, GraphQL::STRING_TYPE,
            method: :project_name,
            null: false,
            description: "Name of the project affected by the error"
      field :sentry_project_slug, GraphQL::STRING_TYPE,
            method: :project_slug,
            null: false,
            description: "Slug of the project affected by the error"
      field :short_id, GraphQL::STRING_TYPE,
            null: false,
            description: "Short ID (Sentry ID) of the error"
      field :status, Types::ErrorTracking::SentryErrorStatusEnum,
            null: false,
            description: "Status of the error"
      field :frequency, [Types::ErrorTracking::SentryErrorFrequencyType],
            null: false,
            description: "Last 24hr stats of the error"
      field :first_release_last_commit, GraphQL::STRING_TYPE,
            null: true,
            description: "Commit the error was first seen"
      field :last_release_last_commit, GraphQL::STRING_TYPE,
            null: true,
            description: "Commit the error was last seen"
      field :first_release_short_version, GraphQL::STRING_TYPE,
            null: true,
            description: "Release version the error was first seen"
      field :last_release_short_version, GraphQL::STRING_TYPE,
            null: true,
            description: "Release version the error was last seen"
      field :gitlab_commit, GraphQL::STRING_TYPE,
            null: true,
            description: "GitLab commit SHA attributed to the Error based on the release version"

      def first_seen
        DateTime.parse(object.first_seen)
      end

      def last_seen
        DateTime.parse(object.last_seen)
      end

      def project_id
        Gitlab::GlobalId.build(model_name: 'Project', id: object.project_id).to_s
      end
    end
  end
end
