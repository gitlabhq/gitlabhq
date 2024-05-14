# frozen_string_literal: true

module Types
  class JiraUsersMappingInputType < BaseInputObject
    graphql_name 'JiraUsersMappingInputType'

    argument :gitlab_id,
      GraphQL::Types::Int,
      required: false,
      description: 'ID of the GitLab user.'
    argument :jira_account_id,
      GraphQL::Types::String,
      required: true,
      description: 'Jira account ID of the user.'
  end
end
