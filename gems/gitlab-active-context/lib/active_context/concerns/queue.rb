# frozen_string_literal: true

module ActiveContext
  module Concerns
    module Queue
      def self.included(base)
        base.extend(ClassMethods)
      end

      def initialize(shard)
        @shard = shard
      end

      def redis_key
        "#{self.class.redis_key}:#{shard}"
      end

      attr_reader :shard

      module ClassMethods
        SLICE_SIZE = 1_000
        SHARD_LIMIT = 1_000

        def limit_throughput?
          false
        end

        # Queues are FIFO by default (scores are counter sequence numbers).
        # Override to return a duration and the queue becomes time-based:
        # scores are due timestamps. Reads see all items by default; only
        # callers passing `due_only: true` are restricted to items whose
        # due time has passed.
        def processing_delay
          nil
        end

        def number_of_shards
          raise NotImplementedError
        end

        def register!
          ActiveContext::Queues.register!(self)
        end

        def push(references)
          refs_by_shard = references.group_by { |ref| ActiveContext::Hasher.consistent_hash(number_of_shards, ref) }
          delay = processing_delay

          ActiveContext::Redis.with_redis do |redis|
            refs_by_shard.each do |shard_number, shard_items|
              set_key = redis_set_key(shard_number)

              if delay
                push_with_delay(redis, set_key, shard_items, delay)
              else
                max = redis.incrby(redis_score_key(shard_number), shard_items.size)
                min = (max - shard_items.size) + 1

                (min..max).zip(shard_items).each_slice(SLICE_SIZE) do |group|
                  redis.zadd(set_key, group)
                end
              end
            end
          end
        end

        def queue_size(shards: queue_shards, include_orphaned: false)
          shards &= queue_shards unless include_orphaned

          ActiveContext::Redis.with_redis do |redis|
            shards.sum do |shard_number|
              redis.zcard(redis_set_key(shard_number))
            end
          end
        end

        def queued_items
          {}.tap do |hash|
            ActiveContext::Redis.with_redis do |redis|
              each_queued_items_by_shard(redis) do |shard_number, specs|
                hash[shard_number] = specs unless specs.empty?
              end
            end
          end
        end

        def each_queued_items_by_shard(
          redis, shards: queue_shards, include_orphaned: false, limit: shard_limit, due_only: false)
          shards &= queue_shards unless include_orphaned

          max_score = if processing_delay && due_only
                        Time.current.to_f
                      else
                        '+inf'
                      end

          shards.each do |shard_number|
            set_key = redis_set_key(shard_number)
            specs = redis.zrangebyscore(set_key, '-inf', max_score, limit: [0, limit], with_scores: true)

            yield shard_number, specs
          end
        end

        def remove_shard_items(redis, shard_number, min_score, max_score)
          redis.zremrangebyscore(
            redis_set_key(shard_number),
            min_score,
            max_score
          )
        end

        def clear_tracking!
          ActiveContext::Redis.with_redis do |redis|
            ::Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
              keys = queue_shards.map { |m| [redis_set_key(m), redis_score_key(m)] }.flatten # rubocop:disable Performance/FlatMap -- more than one level

              if ::Gitlab::Redis::ClusterUtil.cluster?(redis)
                ::Gitlab::Redis::ClusterUtil.batch_unlink(keys, redis)
              else
                redis.unlink(*keys)
              end
            end
          end
        end

        def queue_shards
          0.upto(number_of_shards - 1).to_a
        end

        def shard_limit
          SHARD_LIMIT
        end

        def redis_key
          "#{prefix}:{#{queue_name}}"
        end

        def redis_set_key(shard_number)
          "#{redis_key}:#{shard_number}:zset"
        end

        def redis_score_key(shard_number)
          "#{redis_key}:#{shard_number}:score"
        end

        def queue_name
          name_elements[-1].underscore
        end

        def prefix
          name_elements[..-2].join('_').downcase
        end

        def name_elements
          name.to_s.split('::')
        end

        def preprocess_options
          {
            queue_name: queue_name
          }.merge(extra_preprocess_options)
        end

        def extra_preprocess_options
          {}
        end

        private

        # The FIFO counter gives unique scores for free; timestamps don't.
        # That matters because processed batches are removed by score range:
        # an unfetched item sharing the last fetched score would be deleted
        # unprocessed. Scores are Unix epoch seconds, so adding 0.001 per item
        # spaces them one millisecond apart and keeps one push's scores unique.
        # Collisions across pushes are rare enough to accept.
        def push_with_delay(redis, set_key, shard_items, delay)
          base_score = (Time.current + delay).to_f

          scored_items = shard_items.each_with_index.map do |item, index|
            [base_score + (index * 0.001), item]
          end

          scored_items.each_slice(SLICE_SIZE) do |group|
            redis.zadd(set_key, group)
          end
        end
      end
    end
  end
end
