# frozen_string_literal: true

module Types
  module MergeRequests
    class SavedViewFilterInputType < BaseInputObject
      graphql_name 'MergeRequestSavedViewFilterInput'
      description 'Merge request filter values that can be stored in a saved view.'

      argument :approved_by, [GraphQL::Types::String],
        required: false,
        description: 'Usernames of the approvers.'
      argument :assignee_usernames, [GraphQL::Types::String],
        required: false,
        description: 'Usernames of users assigned to the merge request.'
      argument :author_username, GraphQL::Types::String,
        required: false,
        description: 'Username of the author.'
      argument :draft, GraphQL::Types::Boolean,
        required: false,
        description: 'Limit results to draft merge requests.'
      argument :label_name, [GraphQL::Types::String],
        required: false,
        description: 'Labels applied to the merge request.'
      argument :merged_after, ::Types::TimeType,
        required: false,
        description: 'Merge requests merged after the timestamp.',
        prepare: ->(value, _ctx) { value&.iso8601 }
      argument :merged_before, ::Types::TimeType,
        required: false,
        description: 'Merge requests merged before the timestamp.',
        prepare: ->(value, _ctx) { value&.iso8601 }
      argument :milestone_title, GraphQL::Types::String,
        required: false,
        description: 'Title of the milestone.'
      argument :not, ::Types::MergeRequests::SavedViewNegatedFilterInputType,
        required: false,
        description: 'Filter values to exclude.'
      argument :reviewer_username, GraphQL::Types::String,
        required: false,
        description: 'Username of the reviewer.'
      argument :sort, ::Types::MergeRequestSortEnum,
        required: false,
        description: 'Sort order for the merge requests.',
        prepare: ->(value, _ctx) { value&.to_s }
      argument :source_branches, [GraphQL::Types::String],
        required: false,
        description: 'Source branch names.'
      argument :state, ::Types::MergeRequestStateEnum,
        required: false,
        description: 'Merge request state.'
      argument :target_branches, [GraphQL::Types::String],
        required: false,
        description: 'Target branch names.'
    end
  end
end
