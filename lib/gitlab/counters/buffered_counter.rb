# frozen_string_literal: true

module Gitlab
  module Counters
    class BufferedCounter
      include Gitlab::ExclusiveLeaseHelpers

      WORKER_DELAY = 10.minutes
      WORKER_LOCK_TTL = 10.minutes

      # Refresh keys are set to expire after a very long time,
      # so that they do not occupy Redis memory indefinitely,
      # if for any reason they are not deleted.
      # In practice, a refresh is not expected to take longer than this TTL.
      REFRESH_KEYS_TTL = 14.days
      CLEANUP_BATCH_SIZE = 50
      CLEANUP_INTERVAL_SECONDS = 0.1

      # Limit size of bitmap key to 2^26-1 (~8MB)
      MAX_BITMAP_OFFSET = 67108863

      LUA_FLUSH_INCREMENT_SCRIPT = <<~LUA
        local increment_key, flushed_key = KEYS[1], KEYS[2]
        local increment_value = redis.call("get", increment_key) or 0
        local flushed_value = redis.call("incrby", flushed_key, increment_value)
        if flushed_value == 0 then
          redis.call("del", increment_key, flushed_key)
        else
          redis.call("del", increment_key)
        end
        return flushed_value
      LUA

      def initialize(counter_record, attribute)
        @counter_record = counter_record
        @attribute = attribute
      end

      def get
        redis_state do |redis|
          redis.get(key).to_i
        end
      end

      LUA_INCREMENT_WITH_DEDUPLICATION_SCRIPT = <<~LUA
        local counter_key, refresh_key, refresh_indicator_key = KEYS[1], KEYS[2], KEYS[3]
        local tracking_shard_key, opposing_tracking_shard_key, shards_key = KEYS[4], KEYS[5], KEYS[6]

        local amount, tracking_offset = tonumber(ARGV[1]), tonumber(ARGV[2])

        -- increment to the counter key when not refreshing
        if redis.call("exists", refresh_indicator_key) == 0 then
          return redis.call("incrby", counter_key, amount)
        end

        -- deduplicate and increment to the refresh counter key while refreshing
        local found_duplicate = redis.call("getbit", tracking_shard_key, tracking_offset)
        if found_duplicate == 1 then
          return redis.call("get", refresh_key)
        end

        redis.call("setbit", tracking_shard_key, tracking_offset, 1)
        redis.call("expire", tracking_shard_key, #{REFRESH_KEYS_TTL.seconds})
        redis.call("sadd", shards_key, tracking_shard_key)
        redis.call("expire", shards_key, #{REFRESH_KEYS_TTL.seconds})

        local found_opposing_change = redis.call("getbit", opposing_tracking_shard_key, tracking_offset)
        local increment_without_previous_decrement = amount > 0 and found_opposing_change == 0
        local decrement_with_previous_increment = amount < 0 and found_opposing_change == 1
        local net_change = 0

        if increment_without_previous_decrement or decrement_with_previous_increment then
          net_change = amount
        end

        return redis.call("incrby", refresh_key, net_change)
      LUA

      def increment(increment)
        result = redis_state do |redis|
          redis.eval(LUA_INCREMENT_WITH_DEDUPLICATION_SCRIPT, **increment_args(increment)).to_i
        end

        FlushCounterIncrementsWorker.perform_in(WORKER_DELAY, counter_record.class.name, counter_record.id,
          attribute.to_s)

        result
      end

      def bulk_increment(increments)
        result = redis_state do |redis|
          redis.pipelined do |pipeline|
            increments.each do |increment|
              pipeline.eval(LUA_INCREMENT_WITH_DEDUPLICATION_SCRIPT, **increment_args(increment))
            end
          end
        end

        FlushCounterIncrementsWorker.perform_in(WORKER_DELAY, counter_record.class.name, counter_record.id,
          attribute.to_s)

        result.last.to_i
      end

      LUA_INITIATE_REFRESH_SCRIPT = <<~LUA
        local counter_key, refresh_indicator_key = KEYS[1], KEYS[2]
        redis.call("del", counter_key)
        redis.call("set", refresh_indicator_key, 1, "ex", #{REFRESH_KEYS_TTL.seconds})
      LUA

      def initiate_refresh!
        counter_record.update!(attribute => 0)

        redis_state do |redis|
          redis.eval(LUA_INITIATE_REFRESH_SCRIPT, keys: [key, refresh_indicator_key])
        end
      end

      LUA_FINALIZE_REFRESH_SCRIPT = <<~LUA
        local counter_key, refresh_key, refresh_indicator_key = KEYS[1], KEYS[2], KEYS[3]
        local refresh_amount = redis.call("get", refresh_key) or 0

        redis.call("incrby", counter_key, refresh_amount)
        redis.call("del", refresh_indicator_key, refresh_key)
      LUA

      def finalize_refresh
        redis_state do |redis|
          redis.eval(LUA_FINALIZE_REFRESH_SCRIPT, keys: [key, refresh_key, refresh_indicator_key])
        end

        FlushCounterIncrementsWorker.perform_in(WORKER_DELAY, counter_record.class.name, counter_record.id,
          attribute.to_s)
        ::Counters::CleanupRefreshWorker.perform_async(counter_record.class.name, counter_record.id, attribute)
      end

      def cleanup_refresh
        redis_state do |redis|
          while (shards = redis.spop(shards_key, CLEANUP_BATCH_SIZE))
            redis.del(*shards)
            break if shards.size < CLEANUP_BATCH_SIZE

            sleep CLEANUP_INTERVAL_SECONDS
          end
        end
      end

      def commit_increment!
        with_exclusive_lease do
          flush_amount = amount_to_be_flushed
          next if flush_amount == 0

          # We need the transaction so we can rollback the counter update if `remove_flushed_key` fails.
          counter_record.transaction do
            counter_record.update_counters({ attribute => flush_amount })
            remove_flushed_key
          end

          counter_record.execute_after_commit_callbacks
        end

        counter_record.reset.read_attribute(attribute)
      end

      # amount_to_be_flushed returns the total value to be flushed.
      # The total value is the sum of the following:
      # - current value in the increment_key
      # - any existing value in the flushed_key that has not been flushed
      def amount_to_be_flushed
        redis_state do |redis|
          redis.eval(LUA_FLUSH_INCREMENT_SCRIPT, keys: [key, flushed_key])
        end
      end

      def key
        project_id = counter_record.project.id
        record_name = counter_record.class
        record_id = counter_record.id

        "project:{#{project_id}}:counters:#{record_name}:#{record_id}:#{attribute}"
      end

      def flushed_key
        "#{key}:flushed"
      end

      def refresh_indicator_key
        "#{key}:refresh-in-progress"
      end

      def refresh_key
        "#{key}:refresh"
      end

      private

      attr_reader :counter_record, :attribute

      def increment_args(increment)
        {
          keys: [
            key,
            refresh_key,
            refresh_indicator_key,
            tracking_shard_key(increment),
            opposing_tracking_shard_key(increment),
            shards_key
          ],
          argv: [
            increment.amount,
            tracking_offset(increment)
          ]
        }
      end

      def tracking_shard_key(increment)
        positive?(increment) ? positive_shard_key(increment.ref.to_i) : negative_shard_key(increment.ref.to_i)
      end

      def opposing_tracking_shard_key(increment)
        positive?(increment) ? negative_shard_key(increment.ref.to_i) : positive_shard_key(increment.ref.to_i)
      end

      def shards_key
        "#{refresh_key}:shards"
      end

      def positive_shard_key(ref)
        "#{refresh_key}:+:#{shard_number(ref)}"
      end

      def negative_shard_key(ref)
        "#{refresh_key}:-:#{shard_number(ref)}"
      end

      def shard_number(ref)
        ref / MAX_BITMAP_OFFSET
      end

      def tracking_offset(increment)
        increment.ref.to_i % MAX_BITMAP_OFFSET
      end

      def positive?(increment)
        increment.amount > 0
      end

      def remove_flushed_key
        redis_state do |redis|
          redis.del(flushed_key)
        end
      end

      def redis_state(&block)
        Gitlab::Redis::BufferedCounter.with(&block)
      end

      def with_exclusive_lease(&block)
        lock_key = "#{key}:locked"

        in_lock(lock_key, ttl: WORKER_LOCK_TTL, &block)
      rescue Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError
        # a worker is already updating the counters
      end
    end
  end
end
