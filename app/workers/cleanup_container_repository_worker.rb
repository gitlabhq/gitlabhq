# frozen_string_literal: true

class CleanupContainerRepositoryWorker
  include ApplicationWorker
  include CronjobChildWorker

  data_consistency :always

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

    Projects::ContainerRepository::CleanupTagsService
      .new(container_repository: container_repository, current_user: current_user, params: params)
      .execute
  end

  private

  def valid?
    current_user && container_repository && project
  end

  def project
    container_repository&.project
  end
end
