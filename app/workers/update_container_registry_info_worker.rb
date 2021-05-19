# frozen_string_literal: true

class UpdateContainerRegistryInfoWorker
  include ApplicationWorker

  sidekiq_options retry: 3
  include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

  feature_category :container_registry
  urgency :low

  idempotent!

  def perform
    UpdateContainerRegistryInfoService.new.execute
  end
end
