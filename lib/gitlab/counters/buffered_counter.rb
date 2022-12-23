# frozen_string_literal: true

module Gitlab
  module Counters
    class BufferedCounter
      include Gitlab::ExclusiveLeaseHelpers

      WORKER_DELAY = 10.minutes
      WORKER_LOCK_TTL = 10.minutes

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

      def increment(increment)
        result = redis_state do |redis|
          redis.incrby(key, increment.amount)
        end

        FlushCounterIncrementsWorker.perform_in(WORKER_DELAY, counter_record.class.name, counter_record.id, attribute)

        result
      end

      def bulk_increment(increments)
        result = redis_state do |redis|
          redis.pipelined do |pipeline|
            increments.each do |increment|
              pipeline.incrby(key, increment.amount)
            end
          end
        end

        FlushCounterIncrementsWorker.perform_in(WORKER_DELAY, counter_record.class.name, counter_record.id, attribute)

        result.last
      end

      def reset!
        counter_record.update!(attribute => 0)

        redis_state do |redis|
          redis.del(key)
        end
      end

      def commit_increment!
        with_exclusive_lease do
          flush_amount = amount_to_be_flushed
          next if flush_amount == 0

          counter_record.transaction do
            counter_record.update_counters_with_lease({ attribute => flush_amount })
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

      private

      attr_reader :counter_record, :attribute

      def remove_flushed_key
        redis_state do |redis|
          redis.del(flushed_key)
        end
      end

      def redis_state(&block)
        Gitlab::Redis::SharedState.with(&block)
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
