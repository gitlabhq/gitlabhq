# frozen_string_literal: true

namespace :cache do
  namespace :clear do
    REDIS_CLEAR_BATCH_SIZE = 1000 # There seems to be no speedup when pushing beyond 1,000
    REDIS_SCAN_START_STOP = '0' # Magic value, see http://redis.io/commands/scan

    desc "GitLab | Cache | Clear redis cache"
    task redis: :environment do
      Gitlab::Redis::Cache.with do |redis|
        cache_key_pattern = %W[#{Gitlab::Redis::Cache::CACHE_NAMESPACE}*
                               projects/*/pipeline_status]

        cache_key_pattern.each do |match|
          cursor = REDIS_SCAN_START_STOP
          loop do
            cursor, keys = redis.scan(
              cursor,
              match: match,
              count: REDIS_CLEAR_BATCH_SIZE
            )

            Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
              redis.del(*keys) if keys.any?
            end

            break if cursor == REDIS_SCAN_START_STOP
          end
        end
      end
    end

    task all: [:redis]
  end

  task clear: 'cache:clear:redis'
end
