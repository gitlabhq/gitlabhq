# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module Redis
      # BackfillProjectPipelineStatusTtl cleans up keys written by
      # Gitlab::Cache::Ci::ProjectPipelineStatus by adding a minimum 8-hour ttl
      # to all keys. This either sets or extends the ttl of matching keys.
      #
      class BackfillProjectPipelineStatusTtl # rubocop:disable Migration/BatchedMigrationBaseClass
        def perform(keys)
          # spread out deletes over a 4 hour period starting in 8 hours time
          ttl_duration = 10.hours.to_i
          ttl_jitter = 2.hours.to_i

          Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
            redis.pipelined do |pipeline|
              keys.each { |key| pipeline.expire(key, ttl_duration + rand(-ttl_jitter..ttl_jitter)) }
            end
          end
        end

        def scan_match_pattern
          "#{Gitlab::Redis::Cache::CACHE_NAMESPACE}:project:*:pipeline_status"
        end

        def redis
          @redis ||= Gitlab::Redis::Cache.redis
        end
      end
    end
  end
end
