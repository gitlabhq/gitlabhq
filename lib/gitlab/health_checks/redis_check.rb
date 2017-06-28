module Gitlab
  module HealthChecks
    class RedisCheck
      extend SimpleAbstractCheck

      class << self
        private

        def metric_prefix
          'redis_ping'
        end

        def is_successful?(result)
          result == 'PONG'
        end

        def check
          catch_timeout 10.seconds do
            Gitlab::Redis.with(&:ping)
          end
        end
      end
    end
  end
end
