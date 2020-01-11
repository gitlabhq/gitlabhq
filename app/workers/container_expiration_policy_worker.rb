# frozen_string_literal: true

class ContainerExpirationPolicyWorker
  include ApplicationWorker
  include CronjobQueue

  feature_category :container_registry

  def perform
    ContainerExpirationPolicy.runnable_schedules.preloaded.find_each do |container_expiration_policy|
      ContainerExpirationPolicyService.new(
        container_expiration_policy.project, container_expiration_policy.project.owner
      ).execute(container_expiration_policy)
    end
  end
end
