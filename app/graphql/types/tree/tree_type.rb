# frozen_string_literal: true

module Types
  module Tree
    # rubocop: disable Graphql/AuthorizeTypes
    # This is presented through `Repository` that has its own authorization
    class TreeType < BaseObject
      graphql_name 'Tree'

      present_using ::Projects::TreePresenter

      # Complexity 10 as it triggers a Gitaly call on each render
      field :last_commit, Types::Repositories::CommitType,
        null: true, complexity: 10, calls_gitaly: true, resolver: Resolvers::LastCommitResolver,
        description: 'Last commit for the tree.'

      field :trees, Types::Tree::TreeEntryType.connection_type, null: false,
        description: 'Trees of the tree.'

      field :submodules, Types::Tree::SubmoduleType.connection_type, null: false,
        description: 'Sub-modules of the tree.',
        calls_gitaly: true

      field :blobs, Types::Tree::BlobType.connection_type, null: false,
        description: 'Blobs of the tree.',
        calls_gitaly: true

      field :permalink_path, GraphQL::Types::String, null: true,
        description: "Web path to tree permalink. " \
          "The `permalinkPath` field returns a string that represents the web path to a specific version of " \
          "a directory, identified by its commit SHA. Use this path to create permanent links to directories at " \
          "specific points in your repository's history.",
        calls_gitaly: true,
        experiment: { milestone: '17.11' }

      def trees
        Gitlab::Graphql::Representation::TreeEntry.decorate(object.trees, object.repository)
      end

      def submodules
        Gitlab::Graphql::Representation::SubmoduleTreeEntry.decorate(object.submodules, object)
      end

      def blobs
        Gitlab::Graphql::Representation::TreeEntry.decorate(object.blobs, object.repository)
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
