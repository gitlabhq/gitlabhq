# frozen_string_literal: true

module Types
  class RootStorageStatisticsType < BaseObject
    graphql_name 'RootStorageStatistics'

    authorize :read_statistics

    field :build_artifacts_size, GraphQL::Types::Float, null: false, description: 'CI artifacts size in bytes.'
    field :container_registry_size, GraphQL::Types::Float, null: false, description: 'Container Registry size in bytes.'
    field :container_registry_size_is_estimated, GraphQL::Types::Boolean, method: :registry_size_estimated, null: false,
      description: 'Indicates whether the deduplicated Container Registry size for ' \
        'the namespace is an estimated value or not.'
    field :dependency_proxy_size, GraphQL::Types::Float, null: false, description: 'Dependency Proxy sizes in bytes.'
    field :lfs_objects_size, GraphQL::Types::Float, null: false, description: 'LFS objects size in bytes.'
    field :packages_size, GraphQL::Types::Float, null: false, description: 'Packages size in bytes.'
    field :pipeline_artifacts_size, GraphQL::Types::Float, null: false,
      description: 'CI pipeline artifacts size in bytes.'
    field :registry_size_estimated, GraphQL::Types::Boolean,
      null: false,
      deprecated: { reason: 'Use `container_registry_size_is_estimated`', milestone: '16.2' },
      description: 'Indicates whether the deduplicated Container Registry size for ' \
        'the namespace is an estimated value or not.'
    field :repository_size, GraphQL::Types::Float, null: false, description: 'Git repository size in bytes.'
    field :snippets_size, GraphQL::Types::Float, null: false, description: 'Snippets size in bytes.'
    field :storage_size, GraphQL::Types::Float, null: false, description: 'Total storage in bytes.'
    field :uploads_size, GraphQL::Types::Float, null: false, description: 'Uploads size in bytes.'
    field :wiki_size, GraphQL::Types::Float, null: false, description: 'Wiki size in bytes.'
  end
end

Types::RootStorageStatisticsType.prepend_mod_with('Types::RootStorageStatisticsType')
