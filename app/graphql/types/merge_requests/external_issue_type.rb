# frozen_string_literal: true

module Types
  module MergeRequests
    class ExternalIssueType < BaseObject
      graphql_name 'MergeRequestExternalIssue'
      description 'An external issue referenced by a merge request'

      authorize :read_issue

      field :reference, GraphQL::Types::String,
        null: false,
        method: :to_reference,
        description: 'Reference of the external issue (e.g. JIRA-123).'

      field :title, GraphQL::Types::String,
        null: true,
        description: 'Title of the external issue.'

      field :web_url, GraphQL::Types::String,
        null: true,
        description: 'URL of the external issue on the external tracker.'
    end
  end
end
