# frozen_string_literal: true

module Types
  module WorkItems
    class NegatedWorkItemFilterInputType < BaseInputObject
      graphql_name 'NegatedWorkItemFilterInput'

      argument :assignee_usernames, [GraphQL::Types::String],
        required: false,
        description: 'Usernames of users not assigned to the work item.'
      argument :author_username, [GraphQL::Types::String],
        required: false,
        description: "Username of a user who didn't author the work item."
      argument :label_name, [GraphQL::Types::String],
        required: false,
        description: 'Labels not applied to the work item.'
      argument :milestone_title, [GraphQL::Types::String],
        required: false,
        description: 'Milestone not applied to the work item.'
      argument :milestone_wildcard_id, ::Types::NegatedMilestoneWildcardIdEnum,
        required: false,
        description: 'Filter by negated milestone wildcard values.'
      argument :my_reaction_emoji, GraphQL::Types::String,
        required: false,
        description: 'Filter by reaction emoji not applied by the current user.'
      argument :release_tag, [GraphQL::Types::String],
        required: false,
        description: "Release tag not associated with the work items's milestone. Ignored when parent is a group."
      argument :types, [::Types::IssueTypeEnum], as: :issue_types,
        description: 'Filter out work items by the given types.',
        required: false

      validates mutually_exclusive: [:milestone_title, :milestone_wildcard_id]
    end
  end
end

Types::WorkItems::NegatedWorkItemFilterInputType.prepend_mod_with('Types::WorkItems::NegatedWorkItemFilterInputType')
