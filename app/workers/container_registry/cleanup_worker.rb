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
    STALE_REPAIR_DETAIL_THRESHOLD = 2.hours.freeze
    BATCH_SIZE = 200

    def perform
      reset_stale_deletes
      delete_stale_ongoing_repair_details

      enqueue_delete_container_repository_jobs if ContainerRepository.delete_scheduled.exists?
      enqueue_record_repair_detail_jobs if should_enqueue_record_detail_jobs?
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

    def delete_stale_ongoing_repair_details
      # Deleting stale ongoing repair details would put the project back to the analysis pool
      ContainerRegistry::DataRepairDetail
        .ongoing_since(STALE_REPAIR_DETAIL_THRESHOLD.ago)
        .each_batch(of: BATCH_SIZE) do |batch|
          batch.delete_all
        end
    end

    def enqueue_delete_container_repository_jobs
      ContainerRegistry::DeleteContainerRepositoryWorker.perform_with_capacity
    end

    def enqueue_record_repair_detail_jobs
      ContainerRegistry::RecordDataRepairDetailWorker.perform_with_capacity
    end

    def should_enqueue_record_detail_jobs?
      return false unless Gitlab.com_except_jh?
      return false unless Feature.enabled?(:registry_data_repair_worker)
      return false unless ContainerRegistry::GitlabApiClient.supports_gitlab_api?

      Project.pending_data_repair_analysis.exists?
    end

    def stale_delete_container_repositories
      ContainerRepository.delete_ongoing.with_stale_delete_at(STALE_DELETE_THRESHOLD.ago)
    end
  end
end
