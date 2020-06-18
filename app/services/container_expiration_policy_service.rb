# frozen_string_literal: true

class ContainerExpirationPolicyService < BaseService
  InvalidPolicyError = Class.new(StandardError)

  def execute(container_expiration_policy)
    unless container_expiration_policy.valid?
      container_expiration_policy.disable!
      raise InvalidPolicyError
    end

    container_expiration_policy.schedule_next_run!

    container_expiration_policy.container_repositories.find_each do |container_repository|
      CleanupContainerRepositoryWorker.perform_async(
        nil,
        container_repository.id,
        container_expiration_policy.attributes
          .except('created_at', 'updated_at')
          .merge(container_expiration_policy: true)
      )
    end
  end
end
