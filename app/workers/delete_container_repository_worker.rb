# frozen_string_literal: true

class DeleteContainerRepositoryWorker
  include ApplicationWorker
  include ExclusiveLeaseGuard

  LEASE_TIMEOUT = 1.hour

  attr_reader :container_repository

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(current_user_id, container_repository_id)
    current_user = User.find_by(id: current_user_id)
    @container_repository = ContainerRepository.find_by(id: container_repository_id)
    project = container_repository&.project

    return unless current_user && container_repository && project

    # If a user accidentally attempts to delete the same container registry in quick succession,
    # this can lead to orphaned tags.
    try_obtain_lease do
      Projects::ContainerRepository::DestroyService.new(project, current_user).execute(container_repository)
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # For ExclusiveLeaseGuard concern
  def lease_key
    @lease_key ||= "container_repository:delete:#{container_repository.id}"
  end

  # For ExclusiveLeaseGuard concern
  def lease_timeout
    LEASE_TIMEOUT
  end
end
