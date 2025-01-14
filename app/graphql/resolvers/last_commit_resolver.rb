# frozen_string_literal: true

module Resolvers
  class LastCommitResolver < BaseResolver
    type Types::Repositories::CommitType, null: true

    calls_gitaly!

    alias_method :tree, :object

    def resolve(**args)
      # Ensure merge commits can be returned by sending nil to Gitaly instead of '/'
      path = tree.path == '/' ? nil : tree.path
      commit = Gitlab::Git::Commit.last_for_path(tree.repository,
        ExtractsRef::RefExtractor.qualify_ref(tree.sha, tree.ref_type), path, literal_pathspec: true)

      ::Commit.new(commit, tree.repository.project) if commit
    end
  end
end
