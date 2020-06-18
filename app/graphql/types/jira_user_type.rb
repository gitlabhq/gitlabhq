# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  # Authorization is at project level for owners or admins on mutation level
  class JiraUserType < BaseObject
    graphql_name 'JiraUser'

    field :jira_account_id, GraphQL::STRING_TYPE, null: false,
          description: 'Account id of the Jira user'
    field :jira_display_name, GraphQL::STRING_TYPE, null: false,
          description: 'Display name of the Jira user'
    field :jira_email, GraphQL::STRING_TYPE, null: true,
          description: 'Email of the Jira user, returned only for users with public emails'
    field :gitlab_id, GraphQL::INT_TYPE, null: true,
          description: 'Id of the matched GitLab user'
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
