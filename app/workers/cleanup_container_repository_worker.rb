# frozen_string_literal: true

class CleanupContainerRepositoryWorker
  include ApplicationWorker

  queue_namespace :container_repository

  attr_reader :container_repository, :current_user

  def perform(current_user_id, container_repository_id, params)
    @current_user = User.find_by_id(current_user_id)
    @container_repository = ContainerRepository.find_by_id(container_repository_id)

    return unless valid?

    Projects::ContainerRepository::CleanupTagsService
      .new(project, current_user, params)
      .execute(container_repository)
  end

  private

  def valid?
    current_user && container_repository && project
  end

  def project
    container_repository&.project
  end
end
