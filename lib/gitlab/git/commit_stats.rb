# frozen_string_literal: true

# Gitlab::Git::CommitStats counts the additions, deletions, and total changes
# in a commit.
module Gitlab
  module Git
    class CommitStats
      include Gitlab::Git::WrapsGitalyErrors

      attr_reader :id, :additions, :deletions, :total

      # Instantiate a CommitStats object
      #
      # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/323
      def initialize(repo, commit)
        @id = commit.id
        @additions = 0
        @deletions = 0
        @total = 0

        wrapped_gitaly_errors do
          gitaly_stats(repo, commit)
        end
      end

      def gitaly_stats(repo, commit)
        stats = repo.gitaly_commit_client.commit_stats(@id)
        @additions = stats.additions
        @deletions = stats.deletions
        @total = @additions + @deletions
      end
    end
  end
end
