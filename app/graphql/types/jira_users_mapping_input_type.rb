# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class JiraUsersMappingInputType < BaseInputObject
    graphql_name 'JiraUsersMappingInputType'

    argument :jira_account_id,
               GraphQL::STRING_TYPE,
               required: true,
               description: 'Jira account id of the user'
    argument :gitlab_id,
               GraphQL::INT_TYPE,
               required: false,
               description: 'Id of the GitLab user'
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
