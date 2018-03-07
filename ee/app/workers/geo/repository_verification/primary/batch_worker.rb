module Geo
  module RepositoryVerification
    module Primary
      class BatchWorker
        include ApplicationWorker
        include CronjobQueue
        include ::Gitlab::Utils::StrongMemoize

        HEALTHY_SHARD_CHECKS = [
          Gitlab::HealthChecks::FsShardsCheck,
          Gitlab::HealthChecks::GitalyCheck
        ].freeze

        def perform
          return unless Feature.enabled?('geo_repository_verification')
          return unless Gitlab::Geo.primary?

          Gitlab::Geo::ShardHealthCache.update(healthy_shards)

          healthy_shards.each do |shard_name|
            Geo::RepositoryVerification::Primary::ShardWorker.perform_async(shard_name)
          end
        end

        def healthy_shards
          strong_memoize(:healthy_shards) do
            # For now, we need to perform both Gitaly and direct filesystem checks to ensure
            # the shard is healthy. We take the intersection of the successful checks
            # as the healthy shards.
            HEALTHY_SHARD_CHECKS.map(&:readiness)
              .map { |check_result| check_result.select(&:success) }
              .inject(:&)
              .map { |check_result| check_result.labels[:shard] }
              .compact
              .uniq
          end
        end
      end
    end
  end
end
