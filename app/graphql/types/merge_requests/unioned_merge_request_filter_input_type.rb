# frozen_string_literal: true

module Types
  module MergeRequests
    class UnionedMergeRequestFilterInputType < BaseInputObject
      graphql_name 'UnionedMergeRequestFilterInput'

      argument :reviewer_wildcard, ::Types::ReviewerWildcardIdEnum,
        required: false,
        description: 'Filter by reviewer presence.',
        experiment: { milestone: '17.11' }

      argument :only_reviewer_username, GraphQL::Types::String,
        required: false,
        experiment: { milestone: '17.11' },
        description: <<~DESC
          Filters merge requests that have no reviewer OR only reviewer. Only compatible with reviewerWildcard.
        DESC

      argument :assignee_usernames, [GraphQL::Types::String],
        required: false,
        description: 'Filters MRs that are assigned to at least one of the given users.'
    end
  end
end
