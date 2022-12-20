# frozen_string_literal: true

module ContainerRegistry
  class CleanupWorker
    include ApplicationWorker
    # we don't have any project, user or group context here
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    data_consistency :always
    idempotent!

    feature_category :container_registry

    STALE_DELETE_THRESHOLD = 30.minutes.freeze
    BATCH_SIZE = 200

    def perform
      log_counts

      reset_stale_deletes

      enqueue_delete_container_repository_jobs if ContainerRepository.delete_scheduled.exists?
    end

    private

    def reset_stale_deletes
      ContainerRepository.delete_ongoing.each_batch(of: BATCH_SIZE) do |batch|
        batch.with_stale_delete_at(STALE_DELETE_THRESHOLD.ago).update_all(
          status: :delete_scheduled,
          delete_started_at: nil
        )
      end
    end

    def enqueue_delete_container_repository_jobs
      ContainerRegistry::DeleteContainerRepositoryWorker.perform_with_capacity
    end

    def log_counts
      ::Gitlab::Database::LoadBalancing::Session.current.use_replicas_for_read_queries do
        log_extra_metadata_on_done(
          :delete_scheduled_container_repositories_count,
          ContainerRepository.delete_scheduled.count
        )
        log_extra_metadata_on_done(
          :stale_delete_container_repositories_count,
          stale_delete_container_repositories.count
        )
      end
    end

    def stale_delete_container_repositories
      ContainerRepository.delete_ongoing.with_stale_delete_at(STALE_DELETE_THRESHOLD.ago)
    end
  end
end
