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

    ##
    # Destroy expired job artifacts on GitLab instance
    #
    # This destroy process cannot run for more than 6 minutes. This is for
    # preventing multiple `ExpireBuildArtifactsWorker` CRON jobs run concurrently,
    # which is scheduled every 7 minutes.
    def execute
      in_lock(EXCLUSIVE_LOCK_KEY, ttl: LOCK_TIMEOUT, retries: 1) do
        loop_until(timeout: LOOP_TIMEOUT, limit: LOOP_LIMIT) do
          destroy_artifacts_batch
        end
      end
    end

    private

    def destroy_artifacts_batch
      destroy_job_artifacts_batch || destroy_pipeline_artifacts_batch
    end

    def destroy_job_artifacts_batch
      artifacts = Ci::JobArtifact
        .expired(BATCH_SIZE)
        .unlocked
        .with_destroy_preloads
        .to_a

      return false if artifacts.empty?

      parallel_destroy_batch(artifacts)
      true
    end

    # TODO: Make sure this can also be parallelized
    # https://gitlab.com/gitlab-org/gitlab/-/issues/270973
    def destroy_pipeline_artifacts_batch
      artifacts = Ci::PipelineArtifact.expired(BATCH_SIZE).to_a
      return false if artifacts.empty?

      artifacts.each(&:destroy!)

      true
    end

    def parallel_destroy_batch(job_artifacts)
      Ci::DeletedObject.transaction do
        Ci::DeletedObject.bulk_import(job_artifacts)
        Ci::JobArtifact.id_in(job_artifacts.map(&:id)).delete_all
        destroy_related_records_for(job_artifacts)
      end

      # This is executed outside of the transaction because it depends on Redis
      update_statistics_for(job_artifacts)
      destroyed_artifacts_counter.increment({}, job_artifacts.size)
    end

    # This method is implemented in EE and it must do only database work
    def destroy_related_records_for(job_artifacts); end

    def update_statistics_for(job_artifacts)
      artifacts_by_project = job_artifacts.group_by(&:project)
      artifacts_by_project.each do |project, artifacts|
        delta = -artifacts.sum { |artifact| artifact.size.to_i }
        ProjectStatistics.increment_statistic(
          project, Ci::JobArtifact.project_statistics_name, delta)
      end
    end

    def destroyed_artifacts_counter
      strong_memoize(:destroyed_artifacts_counter) do
        name = :destroyed_job_artifacts_count_total
        comment = 'Counter of destroyed expired job artifacts'

        ::Gitlab::Metrics.counter(name, comment)
      end
    end
  end
end

Ci::DestroyExpiredJobArtifactsService.prepend_if_ee('EE::Ci::DestroyExpiredJobArtifactsService')
