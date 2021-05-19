# frozen_string_literal: true

module Types
  class RepositoryType < BaseObject
    graphql_name 'Repository'

    authorize :download_code

    field :root_ref, GraphQL::STRING_TYPE, null: true, calls_gitaly: true,
          description: 'Default branch of the repository.'
    field :empty, GraphQL::BOOLEAN_TYPE, null: false, method: :empty?, calls_gitaly: true,
          description: 'Indicates repository has no visible content.'
    field :exists, GraphQL::BOOLEAN_TYPE, null: false, method: :exists?, calls_gitaly: true,
          description: 'Indicates a corresponding Git repository exists on disk.'
    field :tree, Types::Tree::TreeType, null: true, resolver: Resolvers::TreeResolver, calls_gitaly: true,
          description: 'Tree of the repository.'
    field :blobs, Types::Repository::BlobType.connection_type, null: true, resolver: Resolvers::BlobsResolver, calls_gitaly: true,
          description: 'Blobs contained within the repository'
    field :branch_names, [GraphQL::STRING_TYPE], null: true, calls_gitaly: true,
          complexity: 170, description: 'Names of branches available in this repository that match the search pattern.',
          resolver: Resolvers::RepositoryBranchNamesResolver
    field :disk_path, GraphQL::STRING_TYPE,
          description: 'Shows a disk path of the repository.',
          null: true,
          authorize: :read_storage_disk_path
  end
end
