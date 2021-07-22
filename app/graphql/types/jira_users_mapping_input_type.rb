# frozen_string_literal: true

module Types
  class JiraUsersMappingInputType < BaseInputObject
    graphql_name 'JiraUsersMappingInputType'

    argument :jira_account_id,
             GraphQL::Types::String,
             required: true,
             description: 'Jira account ID of the user.'
    argument :gitlab_id,
             GraphQL::Types::Int,
             required: false,
             description: 'ID of the GitLab user.'
  end
end
