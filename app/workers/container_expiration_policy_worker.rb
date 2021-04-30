# frozen_string_literal: true

class ContainerExpirationPolicyWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  sidekiq_options retry: 3
  include CronjobQueue
  include ExclusiveLeaseGuard

  feature_category :container_registry

  InvalidPolicyError = Class.new(StandardError)

  BATCH_SIZE = 1000

  def perform
    throttling_enabled? ? perform_throttled : perform_unthrottled
  end

  private

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
      unless loopless_enabled?
        with_runnable_policy do |policy|
          ContainerExpirationPolicy.transaction do
            policy.schedule_next_run!
            ContainerRepository.for_project_id(policy.id)
                               .each_batch do |relation|
                                 relation.update_all(expiration_policy_cleanup_status: :cleanup_scheduled)
                               end
          end
        end
      end

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

  def loopless_enabled?
    Feature.enabled?(:container_registry_expiration_policies_loopless)
  end

  def lease_timeout
    5.hours
  end
end
