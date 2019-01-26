# frozen_string_literal: true

class CleanupContainerRepositoryWorker
  include ApplicationWorker
  include ExclusiveLeaseGuard

  queue_namespace :container_repository

  LEASE_TIMEOUT = 1.hour

  attr_reader :container_repository, :current_user

  def perform(current_user_id, container_repository_id, params)
    @current_user = User.find_by_id(current_user_id)
    @container_repository = ContainerRepository.find_by_id(container_repository_id)

    return unless valid?

    try_obtain_lease do
      Projects::ContainerRepository::CleanupTagsService
        .new(project, current_user, params)
        .execute(container_repository)
    end
  end

  private

  def valid?
    current_user && container_repository && project
  end

  def project
    container_repository&.project
  end

  # For ExclusiveLeaseGuard concern
  def lease_key
    @lease_key ||= "container_repository:cleanup_tags:#{container_repository.id}"
  end

  # For ExclusiveLeaseGuard concern
  def lease_timeout
    LEASE_TIMEOUT
  end

  # For ExclusiveLeaseGuard concern
  def lease_release?
    # we don't allow to execute this worker
    # more often than LEASE_TIMEOUT
    # for given container repository
    false
  end
end
