# frozen_string_literal: true

module Ci
  class ArchiveTracesCronWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    feature_category :continuous_integration

    # rubocop: disable CodeReuse/ActiveRecord
    def perform
      # Archive stale live traces which still resides in redis or database
      # This could happen when Ci::ArchiveTraceWorker sidekiq jobs were lost by receiving SIGKILL
      # More details in https://gitlab.com/gitlab-org/gitlab-foss/issues/36791
      Ci::Build.with_stale_live_trace.find_each(batch_size: 100) do |build|
        Ci::ArchiveTraceService.new.execute(build, worker_name: self.class.name)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
