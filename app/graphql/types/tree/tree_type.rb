# frozen_string_literal: true
module Types
  module Tree
    # rubocop: disable Graphql/AuthorizeTypes
    # This is presented through `Repository` that has its own authorization
    class TreeType < BaseObject
      graphql_name 'Tree'

      # Complexity 10 as it triggers a Gitaly call on each render
      field :last_commit, Types::CommitType,
        null: true, complexity: 10, calls_gitaly: true, resolver: Resolvers::LastCommitResolver,
        description: 'Last commit for the tree'

      field :trees, Types::Tree::TreeEntryType.connection_type, null: false,
            description: 'Trees of the tree',
            resolve: -> (obj, args, ctx) do
              Gitlab::Graphql::Representation::TreeEntry.decorate(obj.trees, obj.repository)
            end

      field :submodules, Types::Tree::SubmoduleType.connection_type, null: false,
            description: 'Sub-modules of the tree',
            calls_gitaly: true, resolve: -> (obj, args, ctx) do
              Gitlab::Graphql::Representation::SubmoduleTreeEntry.decorate(obj.submodules, obj)
            end

      field :blobs, Types::Tree::BlobType.connection_type, null: false,
            description: 'Blobs of the tree',
            calls_gitaly: true, resolve: -> (obj, args, ctx) do
              Gitlab::Graphql::Representation::TreeEntry.decorate(obj.blobs, obj.repository)
            end
      # rubocop: enable Graphql/AuthorizeTypes
    end
  end
end
