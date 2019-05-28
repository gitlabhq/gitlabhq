# frozen_string_literal: true

module Types
  class MilestoneType < BaseObject
    graphql_name 'Milestone'

    authorize :read_milestone

    field :description, GraphQL::STRING_TYPE, null: true
    field :title, GraphQL::STRING_TYPE, null: false
    field :state, GraphQL::STRING_TYPE, null: false

    field :due_date, Types::TimeType, null: true
    field :start_date, Types::TimeType, null: true

    field :created_at, Types::TimeType, null: false
    field :updated_at, Types::TimeType, null: false
  end
end
