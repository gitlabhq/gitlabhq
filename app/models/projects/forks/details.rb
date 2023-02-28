# frozen_string_literal: true

module Projects
  module Forks
    # Class for calculating the divergence of a fork with the source project
    class Details
      include Gitlab::Utils::StrongMemoize

      LATEST_COMMITS_COUNT = 10
      LEASE_TIMEOUT = 15.minutes.to_i
      EXPIRATION_TIME = 8.hours

      def initialize(project, ref)
        @project = project
        @fork_repo = project.repository
        @source_repo = project.fork_source.repository
        @ref = ref
      end

      def counts
        ahead, behind = divergence_counts

        { ahead: ahead, behind: behind }
      end

      def exclusive_lease
        key = ['project_details', project.id, ref].join(':')
        uuid = Gitlab::ExclusiveLease.get_uuid(key)

        Gitlab::ExclusiveLease.new(key, uuid: uuid, timeout: LEASE_TIMEOUT)
      end
      strong_memoize_attr :exclusive_lease

      def syncing?
        exclusive_lease.exists?
      end

      def has_conflicts?
        !(attrs && attrs[:has_conflicts]).nil?
      end

      def update!(params)
        Rails.cache.write(cache_key, params, expires_in: EXPIRATION_TIME)

        @attrs = nil
      end

      private

      attr_reader :project, :fork_repo, :source_repo, :ref

      def cache_key
        @cache_key ||= ['project_fork_details', project.id, ref].join(':')
      end

      def divergence_counts
        sha = fork_repo.commit(ref)&.sha
        source_sha = source_repo.commit&.sha

        return if sha.blank? || source_sha.blank?

        return attrs[:counts] if attrs.present? && attrs[:source_sha] == source_sha && attrs[:sha] == sha

        counts = calculate_divergence_counts(sha, source_sha)

        update!({ sha: sha, source_sha: source_sha, counts: counts })

        counts
      end

      def calculate_divergence_counts(sha, source_sha)
        # If the upstream latest commit exists in the fork repo, then
        # it's possible to calculate divergence counts within the fork repository.
        return fork_repo.diverging_commit_count(sha, source_sha) if fork_repo.commit(source_sha)

        # Otherwise, we need to find a commit that exists both in the fork and upstream
        # in order to use this commit as a base for calculating divergence counts.
        # Considering the fact that a user usually creates a fork to contribute to the upstream,
        # it is expected that they have a limited number of commits ahead of upstream.
        # Let's take the latest N commits and check their existence upstream.
        last_commits_shas = fork_repo.commits(ref, limit: LATEST_COMMITS_COUNT).map(&:sha)
        existence_hash = source_repo.check_objects_exist(last_commits_shas)
        first_matched_commit_sha = last_commits_shas.find { |sha| existence_hash[sha] }

        # If we can't find such a commit, we return early and tell the user that the branches
        # have diverged and action is required.
        return unless first_matched_commit_sha

        # Otherwise, we use upstream to calculate divergence counts from the matched commit
        ahead, behind = source_repo.diverging_commit_count(first_matched_commit_sha, source_sha)
        # And add the number of commits a fork is ahead of the first matched commit
        ahead += last_commits_shas.index(first_matched_commit_sha)

        [ahead, behind]
      end

      def attrs
        @attrs ||= Rails.cache.read(cache_key)
      end
    end
  end
end
