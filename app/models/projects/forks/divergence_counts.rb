# frozen_string_literal: true

module Projects
  module Forks
    # Class for calculating the divergence of a fork with the source project
    class DivergenceCounts
      EXPIRATION_TIME = 8.hours

      def initialize(project, ref)
        @project = project
        @fork_repo = project.repository
        @source_repo = project.fork_source.repository
        @ref = ref
      end

      def counts
        ahead, behind = calculate_divergence_counts

        { ahead: ahead.to_i, behind: behind.to_i }
      end

      private

      attr_reader :project, :fork_repo, :source_repo, :ref

      def cache_key
        @cache_key ||= ['project_forks', project.id, ref, 'divergence_counts']
      end

      def calculate_divergence_counts
        fork_sha = fork_repo.commit(ref).sha
        source_sha = source_repo.commit.sha

        cached_source_sha, cached_fork_sha, counts = Rails.cache.read(cache_key)
        return counts if counts.present? && cached_source_sha == source_sha && cached_fork_sha == fork_sha

        counts =
          Gitlab::Git::CrossRepo.new(fork_repo, source_repo)
            .execute(source_sha) do |cross_repo_sha|
              fork_repo.count_commits_between(fork_sha, cross_repo_sha, left_right: true)
            end

        Rails.cache.write(cache_key, [source_sha, fork_sha, counts], expires_in: EXPIRATION_TIME)

        counts
      end
    end
  end
end
