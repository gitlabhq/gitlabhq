module Gitlab
  module GitalyClient
    class Commit
      # The ID of empty tree.
      # See http://stackoverflow.com/a/40884093/1856239 and https://github.com/git/git/blob/3ad8b5bf26362ac67c9020bf8c30eee54a84f56d/cache.h#L1011-L1012
      EMPTY_TREE_ID = '4b825dc642cb6eb9a060e54bf8d69288fbee4904'.freeze

      def initialize(repository)
        @gitaly_repo = repository.gitaly_repository
        @repository = repository
      end

      def is_ancestor(ancestor_id, child_id)
        stub = GitalyClient.stub(:commit, @repository.storage)
        request = Gitaly::CommitIsAncestorRequest.new(
          repository: @gitaly_repo,
          ancestor_id: ancestor_id,
          child_id: child_id
        )

        stub.commit_is_ancestor(request).value
      end

      def diff_from_parent(commit, options = {})
        request_params = commit_diff_request_params(commit, options)
        request_params[:ignore_whitespace_change] = options.fetch(:ignore_whitespace_change, false)

        response = diff_service_stub.commit_diff(Gitaly::CommitDiffRequest.new(request_params))
        Gitlab::Git::DiffCollection.new(response, options)
      end

<<<<<<< HEAD
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
            paths: options.fetch(:paths, [])
          )

          Gitlab::Git::DiffCollection.new(stub.commit_diff(request), options)
=======
      def commit_deltas(commit)
        request_params = commit_diff_request_params(commit)

        response = diff_service_stub.commit_delta(Gitaly::CommitDeltaRequest.new(request_params))
        response.flat_map do |msg|
          msg.deltas.map { |d| Gitlab::Git::Diff.new(d) }
>>>>>>> upstream/master
        end
      end

      private

      def commit_diff_request_params(commit, options = {})
        parent_id = commit.parents[0]&.id || EMPTY_TREE_ID

        {
          repository: @gitaly_repo,
          left_commit_id: parent_id,
          right_commit_id: commit.id,
          paths: options.fetch(:paths, [])
        }
      end

      def diff_service_stub
        GitalyClient.stub(:diff, @repository.storage)
      end
    end
  end
end
