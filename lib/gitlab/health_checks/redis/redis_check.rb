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
            result == 'PONG'
          end

          def check
            ::Gitlab::HealthChecks::Redis::CacheCheck.check_up &&
              ::Gitlab::HealthChecks::Redis::QueuesCheck.check_up &&
              ::Gitlab::HealthChecks::Redis::SharedStateCheck.check_up
          end
        end
      end
    end
  end
end
