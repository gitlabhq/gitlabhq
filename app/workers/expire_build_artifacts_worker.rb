# frozen_string_literal: true

class ExpireBuildArtifactsWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  # rubocop:disable Scalability/CronWorkerContext
  # This worker does not perform work scoped to a context
  include CronjobQueue
  # rubocop:enable Scalability/CronWorkerContext

  feature_category :continuous_integration

  def perform
    service = Ci::JobArtifacts::DestroyAllExpiredService.new
    artifacts_count = service.execute
    log_extra_metadata_on_done(:destroyed_job_artifacts_count, artifacts_count)
  end
end
