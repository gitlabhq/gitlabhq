# frozen_string_literal: true

module ContainerRegistry
  class DeleteContainerRepositoryWorker
    include ApplicationWorker
    include CronjobChildWorker
    include LimitedCapacity::Worker
    include Gitlab::Utils::StrongMemoize
    extend ::Gitlab::Utils::Override

    data_consistency :always
    queue_namespace :container_repository_delete
    feature_category :container_registry
    urgency :low
    worker_resource_boundary :unknown
    idempotent!

    MAX_CAPACITY = 2
    CLEANUP_TAGS_SERVICE_PARAMS = {
      'name_regex_delete' => '.*',
      'keep_latest' => false,
      'container_expiration_policy' => true # to avoid permissions checks
    }.freeze

    def perform_work
      return unless next_container_repository

      result = delete_tags
      log_delete_tags_service_result(next_container_repository, result)

      if result[:status] == :error || next_container_repository.tags_count != 0
        return update_next_container_repository_status
      end

      next_container_repository.destroy!

      audit_event(next_container_repository)
    rescue StandardError => exception
      update_next_container_repository_status

      Gitlab::ErrorTracking.log_exception(exception, class: self.class.name)
    end

    def remaining_work_count
      ::ContainerRepository.delete_scheduled.limit(max_running_jobs + 1).count
    end

    def max_running_jobs
      MAX_CAPACITY
    end

    private

    def update_next_container_repository_status
      return unless next_container_repository

      if next_container_repository.failed_deletion_count >= ContainerRepository::MAX_DELETION_FAILURES
        next_container_repository.set_delete_failed_status
      else
        next_container_repository.set_delete_scheduled_status
      end
    end

    def delete_tags
      service = Projects::ContainerRepository::CleanupTagsService.new(
        container_repository: next_container_repository,
        params: CLEANUP_TAGS_SERVICE_PARAMS
      )
      service.execute
    end

    def next_container_repository
      strong_memoize(:next_container_repository) do
        ContainerRepository.transaction do
          # we don't care about the order
          repository = ContainerRepository.next_pending_destruction(order_by: nil)

          repository&.tap(&:set_delete_ongoing_status)
        end
      end
    end

    def log_delete_tags_service_result(container_repository, delete_tags_service_result)
      logger.info(
        structured_payload(
          project_id: container_repository.project_id,
          container_repository_id: container_repository.id,
          container_repository_path: container_repository.path,
          tags_size_before_delete: delete_tags_service_result[:original_size],
          deleted_tags_size: delete_tags_service_result[:deleted_size]
        )
      )
    end

    def audit_event(repository)
      # defined in EE
    end
  end
end

ContainerRegistry::DeleteContainerRepositoryWorker.prepend_mod
