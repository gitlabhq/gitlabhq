# frozen_string_literal: true

# Makes sure a commit is kept around when Git garbage collection runs.
# Git GC will delete commits from the repository that are no longer in any
# branches or tags, but we want to keep some of these commits around, for
# example if they have comments or CI builds.
#
# For Geo's sake, pass in multiple shas rather than calling it multiple times,
# to avoid unnecessary syncing.
module Gitlab
  module Git
    class KeepAround
      def self.execute(repository, shas, source:, retry_failed_writes: nil)
        new(repository).execute(shas, source: source, retry_failed_writes: retry_failed_writes)
      end

      def initialize(repository)
        @repository = repository
        @keeparound_requested_counter = Gitlab::Metrics.counter(
          :gitlab_keeparound_refs_requested_total,
          'Counts the number of keep-around refs requested to be created'
        )
        @keeparound_created_counter = Gitlab::Metrics.counter(
          :gitlab_keeparound_refs_created_total,
          'Counts the number of keep-around refs actually created'
        )
      end

      # Returns the SHAs whose keep-around ref could not be written, so a caller can retry
      # them. A caller that already read `retry_failed_keep_around_ref_writes` passes its
      # answer, since a `percentage_of_time` gate re-rolls on every read.
      def execute(shas, source:, retry_failed_writes: nil)
        retry_failed_writes = retry_failed_writes? if retry_failed_writes.nil?

        return old_execute(shas, source: source) unless retry_failed_writes

        new_execute(shas, source: source)
      end

      def kept_around?(sha)
        return true if disabled?

        ref_exists?(keep_around_ref_name(sha))
      end

      delegate :commit_by, :raw_repository, :ref_exists?, :disk_path, to: :@repository
      private :commit_by, :raw_repository, :ref_exists?, :disk_path

      private

      # `Gitlab::Git::Commit.find` rescues an unreachable Gitaly and returns nil, so
      # the SHA is skipped before a write is attempted and the outage is never seen.
      def old_execute(shas, source:)
        return if disabled?

        labels = { source: source }

        shas.uniq.each do |sha|
          next unless sha.present? && commit_by(oid: sha)

          @keeparound_requested_counter.increment(labels)
          Gitlab::AppLogger.info(message: 'Requesting keep-around reference', object_id: sha)

          next if kept_around?(sha)

          # This will still fail if the file is corrupted (e.g. 0 bytes)
          raw_repository.write_ref(keep_around_ref_name(sha), sha)

          @keeparound_created_counter.increment(labels)
          Gitlab::AppLogger.info(message: 'Created keep-around reference', object_id: sha)

        rescue Gitlab::Git::CommandError => ex
          Gitlab::ErrorTracking.track_exception(ex, object_id: sha)
        end
      end

      # Checks the ref before the commit, which is what makes an unreachable Gitaly
      # reportable: `commit_by` returns nil when Gitaly cannot be reached, whereas
      # `kept_around?` raises. The requested counter still precedes the already-kept skip.
      def new_execute(shas, source:)
        return [] if disabled?

        labels = { source: source }
        failed_shas = []

        shas.uniq.each do |sha|
          next unless sha.present?

          already_kept = kept_around?(sha)

          next unless commit_by(oid: sha)

          @keeparound_requested_counter.increment(labels)
          Gitlab::AppLogger.info(message: 'Requesting keep-around reference', object_id: sha)

          next if already_kept

          # This will still fail if the file is corrupted (e.g. 0 bytes)
          raw_repository.write_ref(keep_around_ref_name(sha), sha)

          @keeparound_created_counter.increment(labels)
          Gitlab::AppLogger.info(message: 'Created keep-around reference', object_id: sha)

        rescue Gitlab::Git::Repository::NoRepository => ex
          # Not reported: the repository is gone, so no retry can write the ref. Still
          # rescued, because `Ci::Pipeline#keep_around_commits` calls this inline from
          # an `after_commit` and must not be interrupted.
          Gitlab::ErrorTracking.track_exception(ex, object_id: sha)
        rescue Gitlab::Git::CommandError => ex
          Gitlab::ErrorTracking.track_exception(ex, object_id: sha)
          failed_shas << sha
        end

        failed_shas
      end

      def disabled?
        Feature.enabled?(:disable_keep_around_refs, @repository, type: :ops) ||
          (@repository.project && Feature.enabled?(:disable_keep_around_refs, @repository.project, type: :ops))
      end

      # A repository with no project, such as a snippet's, has no actor to gate on.
      def retry_failed_writes?
        return false unless @repository.project

        Feature.enabled?(:retry_failed_keep_around_ref_writes, @repository.project)
      end

      def keep_around_ref_name(sha)
        "refs/#{::Repository::REF_KEEP_AROUND}/#{sha}"
      end
    end
  end
end
