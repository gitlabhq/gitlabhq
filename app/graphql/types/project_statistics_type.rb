# frozen_string_literal: true

module Types
  class ProjectStatisticsType < BaseObject
    graphql_name 'ProjectStatistics'

    authorize :read_statistics

    field :commit_count, GraphQL::INT_TYPE, null: false # rubocop:disable Graphql/Descriptions

    field :storage_size, GraphQL::INT_TYPE, null: false # rubocop:disable Graphql/Descriptions
    field :repository_size, GraphQL::INT_TYPE, null: false # rubocop:disable Graphql/Descriptions
    field :lfs_objects_size, GraphQL::INT_TYPE, null: false # rubocop:disable Graphql/Descriptions
    field :build_artifacts_size, GraphQL::INT_TYPE, null: false # rubocop:disable Graphql/Descriptions
    field :packages_size, GraphQL::INT_TYPE, null: false # rubocop:disable Graphql/Descriptions
    field :wiki_size, GraphQL::INT_TYPE, null: true # rubocop:disable Graphql/Descriptions
  end
end
