# frozen_string_literal: true

module Types
  class ProjectStatisticsType < BaseObject
    graphql_name 'ProjectStatistics'

    authorize :read_statistics

    field :commit_count, GraphQL::INT_TYPE, null: false,
          description: 'Commit count of the project'

    field :storage_size, GraphQL::INT_TYPE, null: false,
          description: 'Storage size of the project'
    field :repository_size, GraphQL::INT_TYPE, null: false,
          description: 'Repository size of the project'
    field :lfs_objects_size, GraphQL::INT_TYPE, null: false,
          description: 'Large File Storage (LFS) object size of the project'
    field :build_artifacts_size, GraphQL::INT_TYPE, null: false,
          description: 'Build artifacts size of the project'
    field :packages_size, GraphQL::INT_TYPE, null: false,
          description: 'Packages size of the project'
    field :wiki_size, GraphQL::INT_TYPE, null: true,
          description: 'Wiki size of the project'
  end
end
