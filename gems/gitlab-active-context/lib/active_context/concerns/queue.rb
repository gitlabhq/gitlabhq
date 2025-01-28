# frozen_string_literal: true

module ActiveContext
  module Concerns
    module Queue
      def self.included(base)
        base.extend(ClassMethods)
        base.register!
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

        def number_of_shards
          raise NotImplementedError
        end

        def register!
          ActiveContext::Queues.register!(self)
        end

        def push(references)
          refs_by_shard = references.group_by { |ref| ActiveContext::Shard.shard_number(number_of_shards, ref) }

          ActiveContext::Redis.with_redis do |redis|
            refs_by_shard.each do |shard_number, shard_items|
              set_key = redis_set_key(shard_number)

              max = redis.incrby(redis_score_key(shard_number), shard_items.size)
              min = (max - shard_items.size) + 1

              (min..max).zip(shard_items).each_slice(SLICE_SIZE) do |group|
                redis.zadd(set_key, group)
              end
            end
          end
        end

        def queue_size
          ActiveContext::Redis.with_redis do |redis|
            queue_shards.sum do |shard_number|
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

        def each_queued_items_by_shard(redis, shards: queue_shards)
          (shards & queue_shards).each do |shard_number|
            set_key = redis_set_key(shard_number)
            specs = redis.zrangebyscore(set_key, '-inf', '+inf', limit: [0, shard_limit], with_scores: true)

            yield shard_number, specs
          end
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
      end
    end
  end
end
