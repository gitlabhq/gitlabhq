# frozen_string_literal: true

class CiPlatformMetricsUpdateCronWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  sidekiq_options retry: 3

  # This worker does not perform work scoped to a context
  include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

  feature_category :continuous_integration
  urgency :low
  worker_resource_boundary :cpu

  def perform
    CiPlatformMetric.insert_auto_devops_platform_targets!
  end
end
