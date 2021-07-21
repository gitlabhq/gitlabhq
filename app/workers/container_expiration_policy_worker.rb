# frozen_string_literal: true

class ContainerExpirationPolicyWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  include CronjobQueue
  include ExclusiveLeaseGuard

  feature_category :container_registry

  InvalidPolicyError = Class.new(StandardError)

  BATCH_SIZE = 1000

  def perform
    process_stale_ongoing_cleanups
    disable_policies_without_container_repositories
    throttling_enabled? ? perform_throttled : perform_unthrottled
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
    return yield unless ::Gitlab::Database::LoadBalancing.enable?

    ::Gitlab::Database::LoadBalancing::Session.current.use_replicas_for_read_queries(&blk)
  end

  def process_stale_ongoing_cleanups
    threshold = delete_tags_service_timeout.seconds + 30.minutes
    ContainerRepository.with_stale_ongoing_cleanup(threshold.ago)
                       .update_all(expiration_policy_cleanup_status: :cleanup_unfinished)
  end

  def perform_unthrottled
    with_runnable_policy(preloaded: true) do |policy|
      with_context(project: policy.project,
                   user: policy.project.owner) do |project:, user:|
        ContainerExpirationPolicyService.new(project, user)
                                        .execute(policy)
      end
    end
  end

  def perform_throttled
    try_obtain_lease do
      ContainerExpirationPolicies::CleanupContainerRepositoryWorker.perform_with_capacity
    end
  end

  # TODO : remove the preload option when cleaning FF container_registry_expiration_policies_throttling
  def with_runnable_policy(preloaded: false)
    ContainerExpirationPolicy.runnable_schedules.each_batch(of: BATCH_SIZE) do |policies|
      # rubocop: disable CodeReuse/ActiveRecord
      cte = Gitlab::SQL::CTE.new(:batched_policies, policies.limit(BATCH_SIZE))
      # rubocop: enable CodeReuse/ActiveRecord
      scope = cte.apply_to(ContainerExpirationPolicy.all).with_container_repositories

      scope = scope.preloaded if preloaded

      scope.each do |policy|
        if policy.valid?
          yield policy
        else
          disable_invalid_policy!(policy)
        end
      end
    end
  end

  def disable_invalid_policy!(policy)
    policy.disable!
    Gitlab::ErrorTracking.log_exception(
      ::ContainerExpirationPolicyWorker::InvalidPolicyError.new,
      container_expiration_policy_id: policy.id
    )
  end

  def throttling_enabled?
    Feature.enabled?(:container_registry_expiration_policies_throttling)
  end

  def lease_timeout
    5.hours
  end

  def delete_tags_service_timeout
    ::Gitlab::CurrentSettings.current_application_settings.container_registry_delete_tags_service_timeout || 0
  end
end
