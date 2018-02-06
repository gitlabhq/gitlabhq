module Gitlab
  module HealthChecks
    module Redis
      class CacheCheck
        extend SimpleAbstractCheck

        class << self
          def check_up
            check
          end

          private

          def metric_prefix
            'redis_cache_ping'
          end

          def successful?(result)
            result == 'PONG'
          end

          def check
            catch_timeout 10.seconds do
              Gitlab::Redis::Cache.with(&:ping)
            end
          end
        end
      end
    end
  end
end
