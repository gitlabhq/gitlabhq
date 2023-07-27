# frozen_string_literal: true

module BatchedGitRefUpdates
  class CleanupSchedulerWorker
    include ApplicationWorker
    # Ignore RuboCop as the context is added in the service
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    idempotent!
    data_consistency :sticky

    feature_category :gitaly

    def perform
      stats = CleanupSchedulerService.new.execute

      log_extra_metadata_on_done(:stats, stats)
    end
  end
end
