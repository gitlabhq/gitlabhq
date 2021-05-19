# frozen_string_literal: true

class CleanupContainerRepositoryWorker
  include ApplicationWorker

  sidekiq_options retry: 3

  queue_namespace :container_repository
  feature_category :container_registry
  urgency :low
  worker_resource_boundary :unknown
  idempotent!
  loggable_arguments 2

  attr_reader :container_repository, :current_user

  def perform(current_user_id, container_repository_id, params)
    @current_user = User.find_by_id(current_user_id)
    @container_repository = ContainerRepository.find_by_id(container_repository_id)
    @params = params

    return unless valid?

    if run_by_container_expiration_policy?
      container_repository.start_expiration_policy!
    end

    result = Projects::ContainerRepository::CleanupTagsService
      .new(project, current_user, params)
      .execute(container_repository)

    if run_by_container_expiration_policy? && result[:status] == :success
      container_repository.reset_expiration_policy_started_at!
    end
  end

  private

  def valid?
    return true if run_by_container_expiration_policy?

    current_user && container_repository && project
  end

  def run_by_container_expiration_policy?
    @params['container_expiration_policy'] && container_repository.present? && project.present?
  end

  def project
    container_repository&.project
  end
end
