module Geo
  class RepositorySyncWorker < Geo::Scheduler::Secondary::PerShardSchedulerWorker
    def schedule_job(shard_name)
      RepositoryShardSyncWorker.perform_async(shard_name)
    end
  end
end
