module Geo
  module Scheduler
    class PerShardSchedulerWorker
      include ApplicationWorker
      include CronjobQueue
      include ::Gitlab::Geo::LogHelpers
      include ::EachShardWorker

      def perform
        Gitlab::Geo::ShardHealthCache.update(eligible_shard_names)

        each_shard { |shard_name| schedule_job(shard_name) }
      end

      def schedule_job(shard_name)
        raise NotImplementedError
      end
    end
  end
end
