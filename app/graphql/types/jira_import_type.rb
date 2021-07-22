# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  # Authorization is at project level for owners or admins
  class JiraImportType < BaseObject
    graphql_name 'JiraImport'

    field :created_at, Types::TimeType, null: true,
          description: 'Timestamp of when the Jira import was created.'
    field :scheduled_at, Types::TimeType, null: true,
          description: 'Timestamp of when the Jira import was scheduled.'
    field :scheduled_by, Types::UserType, null: true,
          description: 'User that started the Jira import.'
    field :jira_project_key, GraphQL::Types::String, null: false,
          description: 'Project key for the imported Jira project.'
    field :imported_issues_count, GraphQL::Types::Int, null: false,
          description: 'Count of issues that were successfully imported.'
    field :failed_to_import_count, GraphQL::Types::Int, null: false,
          description: 'Count of issues that failed to import.'
    field :total_issue_count, GraphQL::Types::Int, null: false,
          description: 'Total count of issues that were attempted to import.'
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
