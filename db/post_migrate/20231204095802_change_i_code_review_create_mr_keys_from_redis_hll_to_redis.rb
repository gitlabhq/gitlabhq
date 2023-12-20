# frozen_string_literal: true

class ChangeICodeReviewCreateMrKeysFromRedisHllToRedis < Gitlab::Database::Migration[2.2]
  milestone '16.8'

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  REDIS_HLL_PREFIX = '{hll_counters}_i_code_review_create_mr'
  REDIS_PREFIX = '{event_counters}_i_code_review_user_create_mr'

  def up
    # For each old (redis_hll) counter we find the corresponding target (redis) counter and add
    # old value to migrate a metric. If the Redis counter does not exist, it will get created.
    # Since the RedisHLL keys expire after 6 weeks, we will migrate 6 keys at the most.
    Gitlab::Redis::SharedState.with do |redis|
      redis.scan_each(match: "#{REDIS_HLL_PREFIX}-*") do |key|
        redis_key = key.sub(REDIS_HLL_PREFIX, REDIS_PREFIX)
        redis_hll_value = redis.pfcount(key)

        redis.incrby(redis_key, redis_hll_value)
      end
    end
  end

  def down
    # no-op
  end
end
