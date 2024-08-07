# frozen_string_literal: true

# This class is responsible for adding, removing and listing items in a Redis
# set that contains IDs of locked MRs. This set will be used to query the MRs
# that are possibly stuck in locked state and will be unstuck when the
# `StuckMergeJobsWorker` gets scheduled.
module Gitlab
  module MergeRequests
    class LockedSet
      KEY = 'locked_merge_requests'

      def self.add(item_or_collection, rescue_connection_error: true)
        with(rescue_connection_error: rescue_connection_error) do |redis|
          redis.sadd(KEY, item_or_collection)
        end
      end

      def self.remove(item_or_collection)
        with do |redis|
          redis.srem(KEY, item_or_collection)
        end
      end

      def self.each_batch(batch_size)
        with do |redis|
          cursor = 0

          loop do
            cursor, batch = redis.sscan(KEY, cursor, count: batch_size)

            yield(batch)

            break if cursor.to_i == 0
          end
        end
      end

      def self.all
        with do |redis|
          redis.smembers(KEY)
        end
      end

      def self.with(rescue_connection_error: true, &block)
        Gitlab::Redis::SharedState.with(&block) # rubocop: disable CodeReuse/ActiveRecord -- false positive
      rescue ::Redis::BaseConnectionError => e
        raise e unless rescue_connection_error

        # Do not raise an error if we cannot connect to Redis. If
        # Redis::SharedState is unavailable it should not take the site down.
        nil
      end
    end
  end
end
