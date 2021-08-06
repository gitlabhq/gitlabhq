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

        additions, deletions = fetch_stats(repo, commit)

        @additions = additions.to_i
        @deletions = deletions.to_i
        @total = @additions + @deletions
      end

      def fetch_stats(repo, commit)
        Rails.cache.fetch("commit_stats:#{repo.gl_project_path}:#{@id}") do
          stats = wrapped_gitaly_errors do
            repo.gitaly_commit_client.commit_stats(@id)
          end

          [stats.additions, stats.deletions]
        end
      end
    end
  end
end
