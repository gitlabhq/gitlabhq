# frozen_string_literal: true

# Gitlab::Git::CommitStats counts the additions, deletions, and total changes
# in a commit.
module Gitlab
  module Git
    class CommitStats
      include Gitlab::Git::WrapsGitalyErrors

      attr_reader :id, :additions, :deletions, :total, :files

      # Instantiate a CommitStats object
      #
      # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/323
      def initialize(repo, commit)
        @id = commit.id

        additions, deletions, files = ensure_stats_format(repo)

        @additions = additions.to_i
        @deletions = deletions.to_i
        @files = files.to_i
        @total = @additions + @deletions
      end

      def ensure_stats_format(repo)
        cached_stats = fetch_stats(repo)

        if cached_stats.length == 2
          Rails.cache.delete(cache_key(repo))
          cached_stats = fetch_stats(repo)
        end

        cached_stats
      end

      def fetch_stats(repo)
        Rails.cache.fetch(cache_key(repo)) do
          stats = wrapped_gitaly_errors do
            repo.gitaly_commit_client.commit_stats(@id)
          end

          [stats.additions, stats.deletions, stats.files]
        end
      end

      private

      def cache_key(repo)
        "commit_stats:#{repo.gl_project_path}:#{@id}"
      end
    end
  end
end
