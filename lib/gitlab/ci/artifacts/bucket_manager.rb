# frozen_string_literal: true

module Gitlab
  module Ci
    module Artifacts
      module BucketManager
        # Hash tags ensure both keys land in the same Redis cluster slot for atomic operations
        AVAILABLE_BUCKETS_KEY = "{bulk_delete_expired_job_artifacts}:available_buckets"
        OCCUPIED_BUCKETS_KEY = "{bulk_delete_expired_job_artifacts}:occupied_buckets"
        STALE_BUCKET_THRESHOLD = 10.minutes

        # Lua script for atomic bucket claiming
        # Atomically: SPOP from available + ZADD to occupied
        CLAIM_BUCKET_SCRIPT = <<~LUA
          local available_before = redis.call('SMEMBERS', KEYS[1])
          local bucket = redis.call('SPOP', KEYS[1])
          if bucket then
            redis.call('ZADD', KEYS[2], ARGV[1], bucket)
          end
          local available_after = redis.call('SMEMBERS', KEYS[1])
          local occupied_after = redis.call('ZRANGE', KEYS[2], 0, -1)
          return { bucket, available_before, available_after, occupied_after }
        LUA

        class << self
          # Atomically pops a bucket from available set and adds to occupied sorted set with timestamp
          # Logs bucket state immediately after claiming
          def claim_bucket
            with_redis do |redis|
              result = redis.eval(
                CLAIM_BUCKET_SCRIPT,
                keys: [AVAILABLE_BUCKETS_KEY, OCCUPIED_BUCKETS_KEY],
                argv: [Time.current.to_i]
              )

              bucket, available_before, available_after, occupied_after = result

              next unless bucket

              bucket_int = bucket.to_i

              log_bucket_claim(
                claimed_bucket: bucket_int,
                available_buckets_before: available_before,
                available_buckets_after: available_after,
                occupied_buckets_after: occupied_after
              )

              bucket_int
            end
          end

          # Release bucket back to available set, unless it's now invalid due to scale-down
          def release_bucket(bucket, max_buckets:)
            with_redis do |redis|
              if bucket >= max_buckets
                redis.zrem(OCCUPIED_BUCKETS_KEY, bucket.to_s)
              else
                redis.multi do |transaction|
                  transaction.zrem(OCCUPIED_BUCKETS_KEY, bucket.to_s)
                  transaction.sadd(AVAILABLE_BUCKETS_KEY, bucket.to_s)
                end
              end
            end
          end

          def recover_stale_buckets
            with_redis do |redis|
              stale_buckets = redis.zrangebyscore(
                OCCUPIED_BUCKETS_KEY, "-inf", STALE_BUCKET_THRESHOLD.ago.to_i
              )

              stale_buckets.each do |bucket|
                redis.multi do |transaction|
                  transaction.zrem(OCCUPIED_BUCKETS_KEY, bucket)
                  transaction.sadd(AVAILABLE_BUCKETS_KEY, bucket)
                end
              end
              stale_buckets
            end
          end

          # Useful when redis cache resets, concurrency scales up,
          # and if child worker crashes before bucket is moved to occupied
          def enqueue_missing_buckets(max_buckets:)
            with_redis do |redis|
              available = redis.smembers(AVAILABLE_BUCKETS_KEY).map(&:to_i)
              occupied = redis.zrange(OCCUPIED_BUCKETS_KEY, 0, -1).map(&:to_i)
              missing = (0...max_buckets).to_a - available - occupied

              redis.sadd(AVAILABLE_BUCKETS_KEY, missing) if missing.any?
              {
                available: available,
                missing: missing,
                occupied: occupied
              }
            end
          end

          private

          def log_bucket_claim(
            claimed_bucket:,
            available_buckets_before:,
            available_buckets_after:,
            occupied_buckets_after:
          )
            Gitlab::AppLogger.info(
              message: 'Bucket claimed for bulk artifact deletion',
              claimed_bucket: claimed_bucket,
              available_buckets_before: available_buckets_before,
              available_buckets_after: available_buckets_after,
              occupied_buckets_after: occupied_buckets_after
            )
          end

          def with_redis(&)
            Gitlab::Redis::SharedState.with(&) # rubocop:disable CodeReuse/ActiveRecord -- not AR
          end
        end
      end
    end
  end
end
