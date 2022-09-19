# frozen_string_literal: true

module Gitlab
  module HealthChecks
    class GitalyCheck
      extend BaseAbstractCheck

      METRIC_PREFIX = 'gitaly_health_check'

      class << self
        def readiness
          repository_storages.map do |storage_name|
            check(storage_name)
          end
        end

        def metrics
          Gitaly::Server.all.flat_map do |server|
            result, elapsed = with_timing { server.read_writeable? }
            labels = { shard: server.storage }

            [
              metric("#{metric_prefix}_success", result ? 1 : 0, **labels),
              metric("#{metric_prefix}_latency_seconds", elapsed, **labels)
            ]
          end
        end

        def check(storage_name)
          storage_healthy = healthy(storage_name)
          unless storage_healthy[:success]
            return HealthChecks::Result.new(
              name,
              storage_healthy[:success],
              storage_healthy[:message],
              shard: storage_name
            )
          end

          storage_ready = ready(storage_name)
          HealthChecks::Result.new(
            name,
            storage_ready[:success],
            storage_ready[:message],
            shard: storage_name
          )
        end

        def healthy(storage_name)
          serv = Gitlab::GitalyClient::HealthCheckService.new(storage_name)
          serv.check
        end

        def ready(storage_name)
          serv = Gitlab::GitalyClient::ServerService.new(storage_name)
          serv.readiness_check
        end

        private

        def metric_prefix
          METRIC_PREFIX
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
