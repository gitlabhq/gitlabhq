# frozen_string_literal: true

class ContainerExpirationPolicyService < BaseService
  InvalidPolicyError = Class.new(StandardError)

  def execute(container_expiration_policy)
    container_expiration_policy.schedule_next_run!

    container_expiration_policy.container_repositories.find_each do |container_repository|
      CleanupContainerRepositoryWorker.perform_async(
        nil,
        container_repository.id,
        container_expiration_policy.policy_params
                                   .merge(container_expiration_policy: true)
      )
    end
  end
end
