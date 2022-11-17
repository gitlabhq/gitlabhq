# frozen_string_literal: true

module Ci
  module JobArtifacts
    class DestroyBatchService
      include BaseServiceUtility
      include ::Gitlab::Utils::StrongMemoize

      # Danger: Private - Should only be called in Ci Services that pass a batch of job artifacts
      # Not for use outside of the Ci:: namespace

      # Adds the passed batch of job artifacts to the `ci_deleted_objects` table
      # for asyncronous destruction of the objects in Object Storage via the `Ci::DeleteObjectsService`
      # and then deletes the batch of related `ci_job_artifacts` records.
      # Params:
      # +job_artifacts+:: A relation of job artifacts to destroy (fewer than MAX_JOB_ARTIFACT_BATCH_SIZE)
      # +pick_up_at+:: When to pick up for deletion of files
      # Returns:
      # +Hash+:: A hash with status and destroyed_artifacts_count keys
      def initialize(job_artifacts, pick_up_at: nil, skip_projects_on_refresh: false)
        @job_artifacts = job_artifacts.with_destroy_preloads.to_a
        @pick_up_at = pick_up_at
        @skip_projects_on_refresh = skip_projects_on_refresh
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def execute(update_stats: true)
        if @skip_projects_on_refresh
          exclude_artifacts_undergoing_stats_refresh
        else
          track_artifacts_undergoing_stats_refresh
        end

        exclude_trace_artifacts

        return success(destroyed_artifacts_count: 0, statistics_updates: {}) if @job_artifacts.empty?

        destroy_related_records(@job_artifacts)

        destroy_around_hook(@job_artifacts) do
          Ci::DeletedObject.transaction do
            Ci::DeletedObject.bulk_import(@job_artifacts, @pick_up_at)
            Ci::JobArtifact.id_in(@job_artifacts.map(&:id)).delete_all
          end
        end

        after_batch_destroy_hook(@job_artifacts)

        # This is executed outside of the transaction because it depends on Redis
        update_project_statistics! if update_stats
        increment_monitoring_statistics(artifacts_count, artifacts_bytes)

        Gitlab::Ci::Artifacts::Logger.log_deleted(@job_artifacts, 'Ci::JobArtifacts::DestroyBatchService#execute')

        success(destroyed_artifacts_count: artifacts_count,
                statistics_updates: affected_project_statistics)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      private

      # Overriden in EE
      # :nocov:
      def destroy_around_hook(artifacts)
        yield
      end
      # :nocov:

      # Overriden in EE
      def destroy_related_records(artifacts); end

      # Overriden in EE
      def after_batch_destroy_hook(artifacts); end

      # using ! here since this can't be called inside a transaction
      def update_project_statistics!
        affected_project_statistics.each do |project, delta|
          project.increment_statistic_value(Ci::JobArtifact.project_statistics_name, delta)
        end
      end

      def affected_project_statistics
        strong_memoize(:affected_project_statistics) do
          artifacts_by_project = @job_artifacts.group_by(&:project)
          artifacts_by_project.each.with_object({}) do |(project, artifacts), accumulator|
            delta = -artifacts.sum { |artifact| artifact.size.to_i }
            accumulator[project] = delta
          end
        end
      end

      def increment_monitoring_statistics(size, bytes)
        metrics.increment_destroyed_artifacts_count(size)
        metrics.increment_destroyed_artifacts_bytes(bytes)
      end

      def metrics
        @metrics ||= ::Gitlab::Ci::Artifacts::Metrics.new
      end

      def artifacts_count
        strong_memoize(:artifacts_count) do
          @job_artifacts.count
        end
      end

      def artifacts_bytes
        strong_memoize(:artifacts_bytes) do
          @job_artifacts.sum { |artifact| artifact.try(:size) || 0 }
        end
      end

      # Traces should never be destroyed.
      def exclude_trace_artifacts
        _trace_artifacts, @job_artifacts = @job_artifacts.partition(&:trace?)
      end

      def track_artifacts_undergoing_stats_refresh
        project_ids = @job_artifacts.find_all do |artifact|
          artifact.project.refreshing_build_artifacts_size?
        end.map(&:project_id).uniq

        project_ids.each do |project_id|
          Gitlab::ProjectStatsRefreshConflictsLogger.warn_artifact_deletion_during_stats_refresh(
            method: 'Ci::JobArtifacts::DestroyBatchService#execute',
            project_id: project_id
          )
        end
      end

      def exclude_artifacts_undergoing_stats_refresh
        project_ids = Set.new

        @job_artifacts.reject! do |artifact|
          next unless artifact.project.refreshing_build_artifacts_size?

          project_ids << artifact.project_id
        end

        if project_ids.any?
          Gitlab::ProjectStatsRefreshConflictsLogger.warn_skipped_artifact_deletion_during_stats_refresh(
            method: 'Ci::JobArtifacts::DestroyBatchService#execute',
            project_ids: project_ids
          )
        end
      end
    end
  end
end

Ci::JobArtifacts::DestroyBatchService.prepend_mod_with('Ci::JobArtifacts::DestroyBatchService')
