# frozen_string_literal: true

module Types
  class RootStorageStatisticsType < BaseObject
    graphql_name 'RootStorageStatistics'

    authorize :read_statistics

    field :storage_size, GraphQL::INT_TYPE, null: false, description: 'The total storage in bytes'
    field :repository_size, GraphQL::INT_TYPE, null: false, description: 'The Git repository size in bytes'
    field :lfs_objects_size, GraphQL::INT_TYPE, null: false, description: 'The LFS objects size in bytes'
    field :build_artifacts_size, GraphQL::INT_TYPE, null: false, description: 'The CI artifacts size in bytes'
    field :packages_size, GraphQL::INT_TYPE, null: false, description: 'The packages size in bytes'
    field :wiki_size, GraphQL::INT_TYPE, null: false, description: 'The wiki size in bytes'
  end
end
