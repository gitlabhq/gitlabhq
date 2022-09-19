# frozen_string_literal: true

module Gitlab
  module HealthChecks
    module Redis
      module RedisAbstractCheck
        include SimpleAbstractCheck

        def check_up
          successful?(check)
        end

        def redis_instance_class_name
          Gitlab::Redis.const_get(redis_instance_name.camelize, false)
        end

        private

        def metric_prefix
          "redis_#{redis_instance_name}_ping"
        end

        def redis_instance_name
          name.sub(/_check$/, '')
        end

        def successful?(result)
          result == 'PONG'
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def check
          catch_timeout 10.seconds do
            redis_instance_class_name.with(&:ping)
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
