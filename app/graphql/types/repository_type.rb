# frozen_string_literal: true

module Types
  class RepositoryType < BaseObject
    graphql_name 'Repository'

    authorize :read_code

    field :blobs, Types::Repository::BlobType.connection_type, null: true, resolver: Resolvers::BlobsResolver, calls_gitaly: true,
      description: 'Blobs contained within the repository'
    field :branch_names, [GraphQL::Types::String], null: true, calls_gitaly: true,
      complexity: 170, description: 'Names of branches available in this repository that match the search pattern.',
      resolver: Resolvers::RepositoryBranchNamesResolver
    field :disk_path, GraphQL::Types::String,
      description: 'Shows a disk path of the repository.',
      null: true,
      authorize: :read_storage_disk_path
    field :empty, GraphQL::Types::Boolean, null: false, method: :empty?, calls_gitaly: true,
      description: 'Indicates repository has no visible content.'
    field :exists, GraphQL::Types::Boolean, null: false, method: :exists?, calls_gitaly: true,
      description: 'Indicates a corresponding Git repository exists on disk.'
    field :paginated_tree, Types::Tree::TreeType.connection_type, null: true, resolver: Resolvers::PaginatedTreeResolver, calls_gitaly: true,
      connection_extension: Gitlab::Graphql::Extensions::ExternallyPaginatedArrayExtension,
      max_page_size: 100,
      description: 'Paginated tree of the repository.'
    field :root_ref, GraphQL::Types::String, null: true, calls_gitaly: true,
      description: 'Default branch of the repository.'
    field :tree, Types::Tree::TreeType, null: true, resolver: Resolvers::TreeResolver, calls_gitaly: true,
      description: 'Tree of the repository.'
  end
end

Types::RepositoryType.prepend_mod
