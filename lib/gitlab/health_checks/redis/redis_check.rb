# frozen_string_literal: true

module Gitlab
  module HealthChecks
    module Redis
      class RedisCheck
        extend SimpleAbstractCheck

        class << self
          private

          def metric_prefix
            'redis_ping'
          end

          def successful?(result)
            result == true
          end

          def check
            redis_health_checks.all?(&:check_up)
          end

          def redis_health_checks
            [
              Gitlab::HealthChecks::Redis::CacheCheck,
              Gitlab::HealthChecks::Redis::QueuesCheck,
              Gitlab::HealthChecks::Redis::SharedStateCheck,
              Gitlab::HealthChecks::Redis::TraceChunksCheck,
              Gitlab::HealthChecks::Redis::RateLimitingCheck,
              Gitlab::HealthChecks::Redis::SessionsCheck
            ]
          end
        end
      end
    end
  end
end
