# frozen_string_literal: true

class ExpireBuildArtifactsWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  # rubocop:disable Scalability/CronWorkerContext
  # This worker does not perform work scoped to a context
  include CronjobQueue
  # rubocop:enable Scalability/CronWorkerContext

  feature_category :job_artifacts

  def perform
    artifacts_count = Ci::JobArtifacts::DestroyAllExpiredService.new.execute

    log_extra_metadata_on_done(:destroyed_job_artifacts_count, artifacts_count)
  end
end
