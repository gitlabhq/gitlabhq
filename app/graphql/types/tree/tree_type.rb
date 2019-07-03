# frozen_string_literal: true
module Types
  module Tree
    # rubocop: disable Graphql/AuthorizeTypes
    # This is presented through `Repository` that has its own authorization
    class TreeType < BaseObject
      graphql_name 'Tree'

      # Complexity 10 as it triggers a Gitaly call on each render
      field :last_commit, Types::CommitType, null: true, complexity: 10, resolve: -> (tree, args, ctx) do
        tree.repository.last_commit_for_path(tree.sha, tree.path)
      end

      field :trees, Types::Tree::TreeEntryType.connection_type, null: false, resolve: -> (obj, args, ctx) do
        Gitlab::Graphql::Representation::TreeEntry.decorate(obj.trees, obj.repository)
      end

      field :submodules, Types::Tree::SubmoduleType.connection_type, null: false

      field :blobs, Types::Tree::BlobType.connection_type, null: false, resolve: -> (obj, args, ctx) do
        Gitlab::Graphql::Representation::TreeEntry.decorate(obj.blobs, obj.repository)
      end
      # rubocop: enable Graphql/AuthorizeTypes
    end
  end
end
