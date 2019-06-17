# frozen_string_literal: true

module Types
  class TaskCompletionStatus < BaseObject
    graphql_name 'TaskCompletionStatus'
    description 'Completion status of tasks'

    field :count, GraphQL::INT_TYPE, null: false
    field :completed_count, GraphQL::INT_TYPE, null: false
  end
end
