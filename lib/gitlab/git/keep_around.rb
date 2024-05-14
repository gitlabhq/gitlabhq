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
      def self.execute(repository, shas, source:)
        new(repository).execute(shas, source: source)
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

      def execute(shas, source:)
        return if disabled?

        labels = project_labels.merge(source: source)

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

      def kept_around?(sha)
        return true if disabled?

        ref_exists?(keep_around_ref_name(sha))
      end

      delegate :commit_by, :raw_repository, :ref_exists?, :disk_path, to: :@repository
      private :commit_by, :raw_repository, :ref_exists?, :disk_path

      private

      def project_labels
        return { full_path: '' } unless add_project_labels?

        { full_path: @repository.full_path }
      end

      def add_project_labels?
        Feature.enabled?(:label_keep_around_ref_metrics, @repository, type: :ops) ||
          (@repository.project && Feature.enabled?(:label_keep_around_ref_metrics, @repository.project, type: :ops))
      end

      def disabled?
        Feature.enabled?(:disable_keep_around_refs, @repository, type: :ops) ||
          (@repository.project && Feature.enabled?(:disable_keep_around_refs, @repository.project, type: :ops))
      end

      def keep_around_ref_name(sha)
        "refs/#{::Repository::REF_KEEP_AROUND}/#{sha}"
      end
    end
  end
end
