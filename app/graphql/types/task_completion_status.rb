# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  # This is used in `IssueType` and `MergeRequestType` both of which have their
  # own authorization
  class TaskCompletionStatus < BaseObject
    graphql_name 'TaskCompletionStatus'
    description 'Completion status of tasks'

    field :completed_count, GraphQL::Types::Int, null: false,
      description: 'Number of completed tasks.'
    field :count, GraphQL::Types::Int, null: false,
      description: 'Number of total tasks.'
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
