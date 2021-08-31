# frozen_string_literal: true

module Types
  class RootStorageStatisticsType < BaseObject
    graphql_name 'RootStorageStatistics'

    authorize :read_statistics

    field :storage_size, GraphQL::FLOAT_TYPE, null: false, description: 'Total storage in bytes.'
    field :repository_size, GraphQL::FLOAT_TYPE, null: false, description: 'Git repository size in bytes.'
    field :lfs_objects_size, GraphQL::FLOAT_TYPE, null: false, description: 'LFS objects size in bytes.'
    field :build_artifacts_size, GraphQL::FLOAT_TYPE, null: false, description: 'CI artifacts size in bytes.'
    field :packages_size, GraphQL::FLOAT_TYPE, null: false, description: 'Packages size in bytes.'
    field :wiki_size, GraphQL::FLOAT_TYPE, null: false, description: 'Wiki size in bytes.'
    field :snippets_size, GraphQL::FLOAT_TYPE, null: false, description: 'Snippets size in bytes.'
    field :pipeline_artifacts_size, GraphQL::FLOAT_TYPE, null: false, description: 'CI pipeline artifacts size in bytes.'
    field :uploads_size, GraphQL::FLOAT_TYPE, null: false, description: 'Uploads size in bytes.'
  end
end
