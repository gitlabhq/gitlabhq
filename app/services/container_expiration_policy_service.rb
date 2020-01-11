# frozen_string_literal: true

class ContainerExpirationPolicyService < BaseService
  def execute(container_expiration_policy)
    container_expiration_policy.schedule_next_run!

    container_expiration_policy.container_repositories.find_each do |container_repository|
      CleanupContainerRepositoryWorker.perform_async(
        current_user.id,
        container_repository.id,
        container_expiration_policy.attributes.except("created_at", "updated_at")
      )
    end
  end
end
