# frozen_string_literal: true

module Ci
  class DestroyExpiredJobArtifactsService
    include ::Gitlab::ExclusiveLeaseHelpers
    include ::Gitlab::LoopHelpers
    include ::Gitlab::Utils::StrongMemoize

    BATCH_SIZE = 100
    LOOP_TIMEOUT = 5.minutes
    LOOP_LIMIT = 1000
    EXCLUSIVE_LOCK_KEY = 'expired_job_artifacts:destroy:lock'
    LOCK_TIMEOUT = 6.minutes

    def initialize
      @removed_artifacts_count = 0
    end

    ##
    # Destroy expired job artifacts on GitLab instance
    #
    # This destroy process cannot run for more than 6 minutes. This is for
    # preventing multiple `ExpireBuildArtifactsWorker` CRON jobs run concurrently,
    # which is scheduled every 7 minutes.
    def execute
      in_lock(EXCLUSIVE_LOCK_KEY, ttl: LOCK_TIMEOUT, retries: 1) do
        destroy_job_artifacts_with_slow_iteration(Time.current)
      end

      @removed_artifacts_count
    end

    private

    def destroy_job_artifacts_with_slow_iteration(start_at)
      Ci::JobArtifact.expired_before(start_at).each_batch(of: BATCH_SIZE, column: :expire_at, order: :desc) do |relation, index|
        artifacts = relation.unlocked.with_destroy_preloads.to_a

        parallel_destroy_batch(artifacts) if artifacts.any?
        break if loop_timeout?(start_at)
        break if index >= LOOP_LIMIT
      end
    end

    def parallel_destroy_batch(job_artifacts)
      Ci::DeletedObject.transaction do
        Ci::DeletedObject.bulk_import(job_artifacts)
        Ci::JobArtifact.id_in(job_artifacts.map(&:id)).delete_all
        destroy_related_records_for(job_artifacts)
      end

      # This is executed outside of the transaction because it depends on Redis
      update_project_statistics_for(job_artifacts)
      increment_monitoring_statistics(job_artifacts.size)
    end

    # This method is implemented in EE and it must do only database work
    def destroy_related_records_for(job_artifacts); end

    def update_project_statistics_for(job_artifacts)
      artifacts_by_project = job_artifacts.group_by(&:project)
      artifacts_by_project.each do |project, artifacts|
        delta = -artifacts.sum { |artifact| artifact.size.to_i }
        ProjectStatistics.increment_statistic(
          project, Ci::JobArtifact.project_statistics_name, delta)
      end
    end

    def increment_monitoring_statistics(size)
      destroyed_artifacts_counter.increment({}, size)
      @removed_artifacts_count += size
    end

    def destroyed_artifacts_counter
      strong_memoize(:destroyed_artifacts_counter) do
        name = :destroyed_job_artifacts_count_total
        comment = 'Counter of destroyed expired job artifacts'

        ::Gitlab::Metrics.counter(name, comment)
      end
    end

    def loop_timeout?(start_at)
      Time.current > start_at + LOOP_TIMEOUT
    end
  end
end

Ci::DestroyExpiredJobArtifactsService.prepend_if_ee('EE::Ci::DestroyExpiredJobArtifactsService')
