# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  # Authorization is at project level for owners or admins on mutation level
  class JiraUserType < BaseObject
    graphql_name 'JiraUser'

    field :gitlab_id, GraphQL::Types::Int, null: true,
      description: 'ID of the matched GitLab user.'
    field :gitlab_name, GraphQL::Types::String, null: true,
      description: 'Name of the matched GitLab user.'
    field :gitlab_username, GraphQL::Types::String, null: true,
      description: 'Username of the matched GitLab user.'
    field :jira_account_id, GraphQL::Types::String, null: false,
      description: 'Account ID of the Jira user.'
    field :jira_display_name, GraphQL::Types::String, null: false,
      description: 'Display name of the Jira user.'
    field :jira_email,
      GraphQL::Types::String,
      null: true,
      description: 'Email of the Jira user, returned only for users with public emails.'
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
