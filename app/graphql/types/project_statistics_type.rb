# frozen_string_literal: true

module Types
  class ProjectStatisticsType < BaseObject
    graphql_name 'ProjectStatistics'

    authorize :read_statistics

    field :commit_count, GraphQL::INT_TYPE, null: false

    field :storage_size, GraphQL::INT_TYPE, null: false
    field :repository_size, GraphQL::INT_TYPE, null: false
    field :lfs_objects_size, GraphQL::INT_TYPE, null: false
    field :build_artifacts_size, GraphQL::INT_TYPE, null: false
    field :packages_size, GraphQL::INT_TYPE, null: false
    field :wiki_size, GraphQL::INT_TYPE, null: true
  end
end
