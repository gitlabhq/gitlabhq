# frozen_string_literal: true

module ContainerExpirationPolicies
  class CleanupContainerRepositoryWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3
    include LimitedCapacity::Worker
    include Gitlab::Utils::StrongMemoize

    queue_namespace :container_repository
    feature_category :container_registry
    urgency :low
    worker_resource_boundary :unknown
    idempotent!

    LOG_ON_DONE_FIELDS = %i[
      cleanup_status
      cleanup_tags_service_original_size
      cleanup_tags_service_before_truncate_size
      cleanup_tags_service_after_truncate_size
      cleanup_tags_service_cached_tags_count
      cleanup_tags_service_before_delete_size
      cleanup_tags_service_deleted_size
    ].freeze

    def perform_work
      return unless container_repository

      log_extra_metadata_on_done(:container_repository_id, container_repository.id)
      log_extra_metadata_on_done(:project_id, project.id)

      unless allowed_to_run?
        container_repository.cleanup_unscheduled!
        log_extra_metadata_on_done(:cleanup_status, :skipped)
        return
      end

      result = ContainerExpirationPolicies::CleanupService.new(container_repository)
                                                          .execute
      log_on_done(result)
    end

    def max_running_jobs
      ::Gitlab::CurrentSettings.container_registry_expiration_policies_worker_capacity
    end

    def remaining_work_count
      count = cleanup_scheduled_count

      return count if count > max_running_jobs

      count + cleanup_unfinished_count
    end

    private

    def container_repository
      strong_memoize(:container_repository) do
        ContainerRepository.transaction do
          repository = next_container_repository

          repository&.tap do |repo|
            log_info(
              project_id: repo.project_id,
              container_repository_id: repo.id
            )

            repo.start_expiration_policy!
          end
        end
      end
    end

    def next_container_repository
      # rubocop: disable CodeReuse/ActiveRecord
      # We need a lock to prevent two workers from picking up the same row
      next_one_requiring = ContainerRepository.requiring_cleanup
                                              .where(id: next_ten_requiring_ids_from_replica)
                                              .order(:expiration_policy_cleanup_status, :expiration_policy_started_at)
                                              .limit(1)
                                              .lock('FOR UPDATE SKIP LOCKED')
                                              .first
      return next_one_requiring if next_one_requiring

      ContainerRepository.with_unfinished_cleanup
                         .order(:expiration_policy_started_at)
                         .limit(1)
                         .lock('FOR UPDATE SKIP LOCKED')
                         .first
    end

    def next_ten_requiring_ids_from_replica
      use_replica_if_available do
        ContainerRepository.requiring_cleanup
                           .order(:expiration_policy_cleanup_status, :expiration_policy_started_at)
                           .limit(10)
                           .ids
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end

    def cleanup_scheduled_count
      strong_memoize(:cleanup_scheduled_count) do
        limit = max_running_jobs + 1
        ContainerRepository.requiring_cleanup
                           .limit(limit)
                           .count
      end
    end

    def cleanup_unfinished_count
      strong_memoize(:cleanup_unfinished_count) do
        limit = max_running_jobs + 1
        ContainerRepository.with_unfinished_cleanup
                           .limit(limit)
                           .count
      end
    end

    def allowed_to_run?
      return false unless policy&.enabled && policy&.next_run_at

      now = Time.zone.now

      policy.next_run_at < now || (now + max_cleanup_execution_time.seconds < policy.next_run_at)
    end

    def max_cleanup_execution_time
      ::Gitlab::CurrentSettings.container_registry_delete_tags_service_timeout
    end

    def log_info(extra_structure)
      logger.info(structured_payload(extra_structure))
    end

    def log_on_done(result)
      if result.error?
        log_extra_metadata_on_done(:cleanup_status, :error)
        log_extra_metadata_on_done(:cleanup_error_message, result.message)
      end

      LOG_ON_DONE_FIELDS.each do |field|
        value = result.payload[field]

        next if value.nil?

        log_extra_metadata_on_done(field, value)
      end

      log_truncate(result)
      log_cache_ratio(result)
      log_extra_metadata_on_done(:running_jobs_count, running_jobs_count)
    end

    def log_cache_ratio(result)
      tags_count = result.payload[:cleanup_tags_service_after_truncate_size]
      cached_tags_count = result.payload[:cleanup_tags_service_cached_tags_count]

      return unless tags_count && cached_tags_count && tags_count != 0

      ratio = cached_tags_count / tags_count.to_f
      ratio_as_percentage = (ratio * 100).round(2)

      log_extra_metadata_on_done(:cleanup_tags_service_cache_hit_ratio, ratio_as_percentage)
    end

    def log_truncate(result)
      before_truncate_size = result.payload[:cleanup_tags_service_before_truncate_size]
      after_truncate_size = result.payload[:cleanup_tags_service_after_truncate_size]
      truncated = before_truncate_size &&
        after_truncate_size &&
        before_truncate_size != after_truncate_size
      log_extra_metadata_on_done(:cleanup_tags_service_truncated, !!truncated)
    end

    def policy
      project.container_expiration_policy
    end

    def project
      container_repository.project
    end

    def use_replica_if_available(&blk)
      ::Gitlab::Database::LoadBalancing::SessionMap
        .with_sessions([::ApplicationRecord, ::Ci::ApplicationRecord])
        .use_replicas_for_read_queries(&blk)
    end
  end
end
