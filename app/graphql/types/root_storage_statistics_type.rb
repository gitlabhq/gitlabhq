# frozen_string_literal: true

module Types
  class RootStorageStatisticsType < BaseObject
    graphql_name 'RootStorageStatistics'

    authorize :read_statistics

    field :storage_size, GraphQL::FLOAT_TYPE, null: false, description: 'The total storage in bytes.'
    field :repository_size, GraphQL::FLOAT_TYPE, null: false, description: 'The Git repository size in bytes.'
    field :lfs_objects_size, GraphQL::FLOAT_TYPE, null: false, description: 'The LFS objects size in bytes.'
    field :build_artifacts_size, GraphQL::FLOAT_TYPE, null: false, description: 'The CI artifacts size in bytes.'
    field :packages_size, GraphQL::FLOAT_TYPE, null: false, description: 'The packages size in bytes.'
    field :wiki_size, GraphQL::FLOAT_TYPE, null: false, description: 'The wiki size in bytes.'
    field :snippets_size, GraphQL::FLOAT_TYPE, null: false, description: 'The snippets size in bytes.'
    field :pipeline_artifacts_size, GraphQL::FLOAT_TYPE, null: false, description: 'The CI pipeline artifacts size in bytes.'
    field :uploads_size, GraphQL::FLOAT_TYPE, null: false, description: 'The uploads size in bytes.'
  end
end
