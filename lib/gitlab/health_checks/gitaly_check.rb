module Gitlab
  module HealthChecks
    class GitalyCheck
      extend BaseAbstractCheck

      METRIC_PREFIX = 'gitaly_health_check'.freeze

      class << self
        def readiness
          repository_storages.map do |storage_name|
            check(storage_name)
          end
        end

        def metrics
          repository_storages.flat_map do |storage_name|
            result, elapsed = with_timing { check(storage_name) }
            labels = { shard: storage_name }

            [
              metric("#{metric_prefix}_success", successful?(result) ? 1 : 0, **labels),
              metric("#{metric_prefix}_latency_seconds", elapsed, **labels)
            ].flatten
          end
        end

        def check(storage_name)
          serv = Gitlab::GitalyClient::HealthCheckService.new(storage_name)
          result = serv.check
          HealthChecks::Result.new(result[:success], result[:message], shard: storage_name)
        end

        private

        def metric_prefix
          METRIC_PREFIX
        end

        def successful?(result)
          result[:success]
        end

        def repository_storages
          storages.keys
        end

        def storages
          Gitlab.config.repositories.storages
        end
      end
    end
  end
end
