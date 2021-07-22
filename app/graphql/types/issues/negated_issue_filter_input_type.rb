# frozen_string_literal: true

module Types
  module Issues
    class NegatedIssueFilterInputType < BaseInputObject
      graphql_name 'NegatedIssueFilterInput'

      argument :iids, [GraphQL::Types::String],
                required: false,
                description: 'List of IIDs of issues to exclude. For example, `[1, 2]`.'
      argument :label_name, [GraphQL::Types::String],
                required: false,
                description: 'Labels not applied to this issue.'
      argument :milestone_title, [GraphQL::Types::String],
                required: false,
                description: 'Milestone not applied to this issue.'
      argument :assignee_usernames, [GraphQL::Types::String],
                required: false,
                description: 'Usernames of users not assigned to the issue.'
      argument :assignee_id, GraphQL::Types::String,
                required: false,
                description: 'ID of a user not assigned to the issues.'
    end
  end
end

Types::Issues::NegatedIssueFilterInputType.prepend_mod_with('Types::Issues::NegatedIssueFilterInputType')
