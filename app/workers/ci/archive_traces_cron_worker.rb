# frozen_string_literal: true

module Ci
  class ArchiveTracesCronWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    feature_category :continuous_integration
    deduplicate :until_executed, including_scheduled: true

    def perform
      # Archive stale live traces which still resides in redis or database
      # This could happen when Ci::ArchiveTraceWorker sidekiq jobs were lost by receiving SIGKILL
      # More details in https://gitlab.com/gitlab-org/gitlab-foss/issues/36791

      Ci::ArchiveTraceService.new.batch_execute(worker_name: self.class.name)
    end
  end
end
