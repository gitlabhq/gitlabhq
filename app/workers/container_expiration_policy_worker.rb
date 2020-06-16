# frozen_string_literal: true

class ContainerExpirationPolicyWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker
  include CronjobQueue

  feature_category :container_registry

  def perform
    ContainerExpirationPolicy.runnable_schedules.preloaded.find_each do |container_expiration_policy|
      with_context(project: container_expiration_policy.project,
                   user: container_expiration_policy.project.owner) do |project:, user:|
        ContainerExpirationPolicyService.new(project, user)
          .execute(container_expiration_policy)
      rescue ContainerExpirationPolicyService::InvalidPolicyError => e
        Gitlab::ErrorTracking.log_exception(e, container_expiration_policy_id: container_expiration_policy.id)
      end
    end
  end
end
