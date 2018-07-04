module Geo
  module RepositoryVerification
    module Primary
      class BatchWorker < Geo::Scheduler::Primary::PerShardSchedulerWorker
        def perform
          return unless Gitlab::Geo.repository_verification_enabled?

          super
        end

        def schedule_job(shard_name)
          Geo::RepositoryVerification::Primary::ShardWorker.perform_async(shard_name)
        end
      end
    end
  end
end
