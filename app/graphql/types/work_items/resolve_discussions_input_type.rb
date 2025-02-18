# frozen_string_literal: true

module Types
  module WorkItems
    class ResolveDiscussionsInputType < BaseInputObject
      graphql_name 'WorkItemResolveDiscussionsInput'

      argument :discussion_id, GraphQL::Types::String,
        description: 'ID of a discussion to resolve.',
        required: false
      argument :noteable_id, ::Types::GlobalIDType[::Noteable],
        required: true,
        description: 'Global ID of the noteable where discussions will be resolved when the work item is created. ' \
          'Only `MergeRequestID` is supported at the moment.'
    end
  end
end
