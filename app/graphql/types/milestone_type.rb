# frozen_string_literal: true

module Types
  class MilestoneType < BaseObject
    graphql_name 'Milestone'

    authorize :read_milestone

    field :description, GraphQL::STRING_TYPE, null: true # rubocop:disable Graphql/Descriptions
    field :title, GraphQL::STRING_TYPE, null: false # rubocop:disable Graphql/Descriptions
    field :state, GraphQL::STRING_TYPE, null: false # rubocop:disable Graphql/Descriptions

    field :due_date, Types::TimeType, null: true # rubocop:disable Graphql/Descriptions
    field :start_date, Types::TimeType, null: true # rubocop:disable Graphql/Descriptions

    field :created_at, Types::TimeType, null: false # rubocop:disable Graphql/Descriptions
    field :updated_at, Types::TimeType, null: false # rubocop:disable Graphql/Descriptions
  end
end
