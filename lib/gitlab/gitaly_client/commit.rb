module Gitlab
  module GitalyClient
    class Commit
      # The ID of empty tree.
      # See http://stackoverflow.com/a/40884093/1856239 and https://github.com/git/git/blob/3ad8b5bf26362ac67c9020bf8c30eee54a84f56d/cache.h#L1011-L1012
      EMPTY_TREE_ID = '4b825dc642cb6eb9a060e54bf8d69288fbee4904'.freeze

      attr_accessor :stub

      def initialize(repository)
        @gitaly_repo = repository.gitaly_repository
        @stub = Gitaly::Commit::Stub.new(nil, nil, channel_override: repository.gitaly_channel)
      end

      def is_ancestor(ancestor_id, child_id)
        request = Gitaly::CommitIsAncestorRequest.new(
          repository: @gitaly_repo,
          ancestor_id: ancestor_id,
          child_id: child_id
        )

        @stub.commit_is_ancestor(request).value
      end

      class << self
        def diff_from_parent(commit, options = {})
          repository = commit.project.repository
          gitaly_repo = repository.gitaly_repository
          stub = Gitaly::Diff::Stub.new(nil, nil, channel_override: repository.gitaly_channel)
          parent = commit.parents[0]
          parent_id = parent ? parent.id : EMPTY_TREE_ID
          request = Gitaly::CommitDiffRequest.new(
            repository: gitaly_repo,
            left_commit_id: parent_id,
            right_commit_id: commit.id,
            ignore_whitespace_change: options.fetch(:ignore_whitespace_change, false),
            paths: options.fetch(:paths, []),
          )

          Gitlab::Git::DiffCollection.new(stub.commit_diff(request), options)
        end
      end
    end
  end
end
