# frozen_string_literal: true

class DeleteContainerRepositoryWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker
  include ExclusiveLeaseGuard

  data_consistency :always

  sidekiq_options retry: 3

  queue_namespace :container_repository
  feature_category :container_registry

  def perform(current_user_id, container_repository_id); end
end
