# frozen_string_literal: true

module Types
  module MergeRequests
    class SavedViewNegatedFilterInputType < BaseInputObject
      graphql_name 'MergeRequestSavedViewNegatedFilterInput'
      description 'Merge request filter values to exclude in a saved view.'

      argument :approved_by, [GraphQL::Types::String],
        required: false,
        description: 'Usernames of approvers to exclude.'
      argument :assignee_usernames, [GraphQL::Types::String],
        required: false,
        description: 'Usernames of assignees to exclude.'
      argument :author_username, GraphQL::Types::String,
        required: false,
        description: 'Username of the author to exclude.'
      argument :label_name, [GraphQL::Types::String],
        required: false,
        description: 'Labels to exclude.'
      argument :milestone_title, GraphQL::Types::String,
        required: false,
        description: 'Title of the milestone to exclude.'
      argument :reviewer_username, GraphQL::Types::String,
        required: false,
        description: 'Username of the reviewer to exclude.'
      argument :source_branches, [GraphQL::Types::String],
        required: false,
        description: 'Source branch names to exclude.'
      argument :target_branches, [GraphQL::Types::String],
        required: false,
        description: 'Target branch names to exclude.'
    end
  end
end
