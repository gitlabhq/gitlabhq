# frozen_string_literal: true

module Types
  class ProjectStatisticsType < BaseObject
    graphql_name 'ProjectStatistics'

    authorize :read_statistics

    field :commit_count, GraphQL::Types::Float, null: false,
      description: 'Commit count of the project.'

    field :build_artifacts_size, GraphQL::Types::Float, null: false,
      description: 'Build artifacts size of the project in bytes.'
    field :container_registry_size,
      GraphQL::Types::Float,
      null: true,
      description: 'Container Registry size of the project in bytes.'
    field :lfs_objects_size,
      GraphQL::Types::Float,
      null: false,
      description: 'Large File Storage (LFS) object size of the project in bytes.'
    field :packages_size, GraphQL::Types::Float, null: false,
      description: 'Packages size of the project in bytes.'
    field :pipeline_artifacts_size, GraphQL::Types::Float, null: true,
      description: 'CI Pipeline artifacts size in bytes.'
    field :repository_size, GraphQL::Types::Float, null: false,
      description: 'Repository size of the project in bytes.'
    field :snippets_size, GraphQL::Types::Float, null: true,
      description: 'Snippets size of the project in bytes.'
    field :storage_size, GraphQL::Types::Float, null: false,
      description: 'Storage size of the project in bytes.'
    field :uploads_size, GraphQL::Types::Float, null: true,
      description: 'Uploads size of the project in bytes.'
    field :wiki_size, GraphQL::Types::Float, null: true,
      description: 'Wiki size of the project in bytes.'
  end
end

Types::ProjectStatisticsType.prepend_mod_with('Types::ProjectStatisticsType')
