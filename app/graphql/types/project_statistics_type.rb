# frozen_string_literal: true

module Types
  class ProjectStatisticsType < BaseObject
    graphql_name 'ProjectStatistics'

    authorize :read_statistics

    field :commit_count, GraphQL::FLOAT_TYPE, null: false,
          description: 'Commit count of the project.'

    field :storage_size, GraphQL::FLOAT_TYPE, null: false,
          description: 'Storage size of the project in bytes.'
    field :repository_size, GraphQL::FLOAT_TYPE, null: false,
          description: 'Repository size of the project in bytes.'
    field :lfs_objects_size, GraphQL::FLOAT_TYPE, null: false,
          description: 'Large File Storage (LFS) object size of the project in bytes.'
    field :build_artifacts_size, GraphQL::FLOAT_TYPE, null: false,
          description: 'Build artifacts size of the project in bytes.'
    field :packages_size, GraphQL::FLOAT_TYPE, null: false,
          description: 'Packages size of the project in bytes.'
    field :wiki_size, GraphQL::FLOAT_TYPE, null: true,
          description: 'Wiki size of the project in bytes.'
    field :snippets_size, GraphQL::FLOAT_TYPE, null: true,
          description: 'Snippets size of the project in bytes.'
    field :uploads_size, GraphQL::FLOAT_TYPE, null: true,
          description: 'Uploads size of the project in bytes.'
  end
end
