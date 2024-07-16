# frozen_string_literal: true

module Ci
  class UpdateLockedUnknownArtifactsWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :sticky
    urgency :throttled

    # rubocop:disable Scalability/CronWorkerContext
    # This worker does not perform work scoped to a context
    include CronjobQueue
    # rubocop:enable Scalability/CronWorkerContext

    feature_category :job_artifacts

    def perform
      artifact_counts = Ci::JobArtifacts::UpdateUnknownLockedStatusService.new.execute

      log_extra_metadata_on_done(:removed_count, artifact_counts[:removed])
      log_extra_metadata_on_done(:locked_count, artifact_counts[:locked])
    end
  end
end
