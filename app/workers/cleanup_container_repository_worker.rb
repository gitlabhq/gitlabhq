# frozen_string_literal: true

class CleanupContainerRepositoryWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  queue_namespace :container_repository
  feature_category :container_registry
  loggable_arguments 2

  attr_reader :container_repository, :current_user

  def perform(current_user_id, container_repository_id, params)
    @current_user = User.find_by_id(current_user_id)
    @container_repository = ContainerRepository.find_by_id(container_repository_id)
    @params = params

    return unless valid?

    Projects::ContainerRepository::CleanupTagsService
      .new(project, current_user, params)
      .execute(container_repository)
  end

  private

  def valid?
    return true if run_by_container_expiration_policy?

    current_user && container_repository && project
  end

  def run_by_container_expiration_policy?
    @params['container_expiration_policy'] && container_repository && project
  end

  def project
    container_repository&.project
  end
end
