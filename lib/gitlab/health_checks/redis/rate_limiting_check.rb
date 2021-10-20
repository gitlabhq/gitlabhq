# frozen_string_literal: true

module Gitlab
  module HealthChecks
    module Redis
      class RateLimitingCheck
        extend SimpleAbstractCheck

        class << self
          def check_up
            check
          end

          private

          def metric_prefix
            'redis_rate_limiting_ping'
          end

          def successful?(result)
            result == 'PONG'
          end

          # rubocop: disable CodeReuse/ActiveRecord
          def check
            catch_timeout 10.seconds do
              Gitlab::Redis::RateLimiting.with(&:ping)
            end
          end
          # rubocop: enable CodeReuse/ActiveRecord
        end
      end
    end
  end
end
