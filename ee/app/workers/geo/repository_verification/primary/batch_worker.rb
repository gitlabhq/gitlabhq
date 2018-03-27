module Geo
  module RepositoryVerification
    module Primary
      class BatchWorker < Geo::Scheduler::Primary::PerShardSchedulerWorker
        def perform
          return unless Feature.enabled?('geo_repository_verification')

          super
        end

        def schedule_job(shard_name)
          Geo::RepositoryVerification::Primary::ShardWorker.perform_async(shard_name)
        end
      end
    end
  end
end
