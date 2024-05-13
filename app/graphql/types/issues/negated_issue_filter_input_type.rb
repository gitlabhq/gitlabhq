# frozen_string_literal: true

module Types
  module Issues
    class NegatedIssueFilterInputType < BaseInputObject
      graphql_name 'NegatedIssueFilterInput'

      argument :assignee_id, GraphQL::Types::String,
        required: false,
        description: 'ID of a user not assigned to the issues.'
      argument :assignee_usernames, [GraphQL::Types::String],
        required: false,
        description: 'Usernames of users not assigned to the issue.'
      argument :author_username, [GraphQL::Types::String],
        required: false,
        description: "Username of a user who didn't author the issue."
      argument :iids, [GraphQL::Types::String],
        required: false,
        description: 'List of IIDs of issues to exclude. For example, `[1, 2]`.'
      argument :label_name, [GraphQL::Types::String],
        required: false,
        description: 'Labels not applied to this issue.'
      argument :milestone_title, [GraphQL::Types::String],
        required: false,
        description: 'Milestone not applied to this issue.'
      argument :milestone_wildcard_id, ::Types::NegatedMilestoneWildcardIdEnum,
        required: false,
        description: 'Filter by negated milestone wildcard values.'
      argument :my_reaction_emoji, GraphQL::Types::String,
        required: false,
        description: 'Filter by reaction emoji applied by the current user.'
      argument :release_tag, [GraphQL::Types::String],
        required: false,
        description: "Release tag not associated with the issue's milestone. Ignored when parent is a group."
      argument :types, [Types::IssueTypeEnum],
        as: :issue_types,
        description: 'Filters out issues by the given issue types.',
        required: false

      validates mutually_exclusive: [:milestone_title, :milestone_wildcard_id]
    end
  end
end

Types::Issues::NegatedIssueFilterInputType.prepend_mod_with('Types::Issues::NegatedIssueFilterInputType')
