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
      def initialize(job_artifacts, pick_up_at: nil, fix_expire_at: fix_expire_at?, skip_projects_on_refresh: false)
        @job_artifacts = job_artifacts.with_destroy_preloads.to_a
        @pick_up_at = pick_up_at
        @fix_expire_at = fix_expire_at
        @skip_projects_on_refresh = skip_projects_on_refresh
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def execute(update_stats: true)
        if @skip_projects_on_refresh
          exclude_artifacts_undergoing_stats_refresh
        else
          track_artifacts_undergoing_stats_refresh
        end

        # Detect and fix artifacts that had `expire_at` wrongly backfilled by migration
        # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/47723
        detect_and_fix_wrongly_expired_artifacts

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

      # This detects and fixes job artifacts that have `expire_at` wrongly backfilled by the migration
      # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/47723.
      # These job artifacts will not be deleted and will have their `expire_at` removed.
      #
      # The migration would have backfilled `expire_at`
      # to midnight on the 22nd of the month of the local timezone,
      # storing it as UTC time in the database.
      #
      # If the timezone setting has changed since the migration,
      # the `expire_at` stored in the database could have changed to a different local time other than midnight.
      # For example:
      # - changing timezone from UTC+02:00 to UTC+02:30 would change the `expire_at` in local time 00:00:00 to 00:30:00.
      # - changing timezone from UTC+00:00 to UTC-01:00 would change the `expire_at` in local time 00:00:00 to 23:00:00 on the previous day (21st).
      #
      # Therefore job artifacts that have `expire_at` exactly on the 00, 30 or 45 minute mark
      # on the dates 21, 22, 23 of the month will not be deleted.
      # https://en.wikipedia.org/wiki/List_of_UTC_time_offsets
      def detect_and_fix_wrongly_expired_artifacts
        return unless @fix_expire_at

        wrongly_expired_artifacts, @job_artifacts = @job_artifacts.partition { |artifact| wrongly_expired?(artifact) }

        remove_expire_at(wrongly_expired_artifacts) if wrongly_expired_artifacts.any?
      end

      def fix_expire_at?
        Feature.enabled?(:ci_detect_wrongly_expired_artifacts)
      end

      def wrongly_expired?(artifact)
        return false unless artifact.expire_at.present?

        # Although traces should never have expiration dates that don't match time & date here.
        # we can explicitly exclude them by type since they should never be destroyed.
        artifact.trace? || (match_date?(artifact.expire_at) && match_time?(artifact.expire_at))
      end

      def match_date?(expire_at)
        [21, 22, 23].include?(expire_at.day)
      end

      def match_time?(expire_at)
        %w[00:00.000 30:00.000 45:00.000].include?(expire_at.strftime('%M:%S.%L'))
      end

      def remove_expire_at(artifacts)
        Ci::JobArtifact.id_in(artifacts).update_all(expire_at: nil)

        Gitlab::AppLogger.info(message: "Fixed expire_at from artifacts.", fixed_artifacts_expire_at_count: artifacts.count)
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
