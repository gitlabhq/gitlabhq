# frozen_string_literal: true

class ContainerExpirationPolicyWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  # rubocop:disable Scalability/CronWorkerContext
  # This worker does not perform work scoped to a context
  include CronjobQueue
  # rubocop:enable Scalability/CronWorkerContext

  include ExclusiveLeaseGuard

  feature_category :container_registry

  InvalidPolicyError = Class.new(StandardError)

  BATCH_SIZE = 1000

  def perform
    process_stale_ongoing_cleanups
    disable_policies_without_container_repositories
    try_obtain_lease do
      ContainerExpirationPolicies::CleanupContainerRepositoryWorker.perform_with_capacity
    end
    log_counts
  end

  private

  def disable_policies_without_container_repositories
    ContainerExpirationPolicy.active.each_batch(of: BATCH_SIZE) do |policies|
      policies.without_container_repositories
              .update_all(enabled: false)
    end
  end

  def log_counts
    use_replica_if_available do
      required_count = ContainerRepository.requiring_cleanup.count
      unfinished_count = ContainerRepository.with_unfinished_cleanup.count

      log_extra_metadata_on_done(:cleanup_required_count, required_count)
      log_extra_metadata_on_done(:cleanup_unfinished_count, unfinished_count)
      log_extra_metadata_on_done(:cleanup_total_count, required_count + unfinished_count)
    end
  end

  # data_consistency :delayed not used as this is a cron job and those jobs are
  # not perfomed with a delay
  # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/63635#note_603771207
  def use_replica_if_available(&blk)
    ::Gitlab::Database::LoadBalancing::SessionMap
      .current(ContainerRepository.load_balancer)
      .use_replicas_for_read_queries(&blk)
  end

  def process_stale_ongoing_cleanups
    threshold = delete_tags_service_timeout.seconds + 30.minutes
    ContainerRepository.with_stale_ongoing_cleanup(threshold.ago)
                       .update_all(expiration_policy_cleanup_status: :cleanup_unfinished)
  end

  def lease_timeout
    5.hours
  end

  def delete_tags_service_timeout
    ::Gitlab::CurrentSettings.current_application_settings.container_registry_delete_tags_service_timeout || 0
  end
end
