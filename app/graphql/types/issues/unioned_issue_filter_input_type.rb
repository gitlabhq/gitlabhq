# frozen_string_literal: true

module Types
  module Issues
    class UnionedIssueFilterInputType < BaseInputObject
      graphql_name 'UnionedIssueFilterInput'

      argument :assignee_usernames, [GraphQL::Types::String],
        required: false,
        description: 'Filters issues that are assigned to at least one of the given users.'
      argument :author_usernames, [GraphQL::Types::String],
        required: false,
        description: 'Filters issues that are authored by one of the given users.'
      argument :label_names, [GraphQL::Types::String],
        required: false,
        description: 'Filters issues that have at least one of the given labels.'
    end
  end
end
