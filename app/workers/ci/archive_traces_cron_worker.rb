# frozen_string_literal: true

module Ci
  class ArchiveTracesCronWorker
    include ApplicationWorker
    include CronjobQueue

    # rubocop: disable CodeReuse/ActiveRecord
    def perform
      # Archive stale live traces which still resides in redis or database
      # This could happen when ArchiveTraceWorker sidekiq jobs were lost by receiving SIGKILL
      # More details in https://gitlab.com/gitlab-org/gitlab-ce/issues/36791
      Ci::Build.finished.with_live_trace.find_each(batch_size: 100) do |build|
        Ci::ArchiveTraceService.new.execute(build, worker_name: self.class.name)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
