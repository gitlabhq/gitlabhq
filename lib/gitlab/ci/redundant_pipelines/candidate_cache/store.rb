# frozen_string_literal: true

module Gitlab
  module Ci
    module RedundantPipelines
      class CandidateCache
        # Redis access for CandidateCache. Speaks pipeline keys, so its owner never
        # handles Redis members or failures.
        class Store
          # Removing the entries in the call that returns them is what gives one
          # caller sole ownership. The newest are claimed first, because they are the
          # pipelines most likely to still be running.
          #   ARGV[1] pipeline_id, ARGV[2] limit
          CLAIM = ::Labkit::Redis::Script.new(<<~LUA)
            local candidates = KEYS[1]
            local pipeline_id, limit = tonumber(ARGV[1]), tonumber(ARGV[2])

            local claimed = redis.call(
              'zrevrangebyscore', candidates, '(' .. pipeline_id, '-inf', 'LIMIT', 0, limit
            )

            if #claimed > 0 then
              redis.call('zrem', candidates, unpack(claimed))
            end

            return claimed
          LUA

          #   ARGV[1] pipeline_id, ARGV[2] member, ARGV[3] ttl, ARGV[4] max_size
          REGISTER = ::Labkit::Redis::Script.new(<<~LUA)
            local candidates = KEYS[1]
            local pipeline_id, member = tonumber(ARGV[1]), ARGV[2]
            local ttl, max_size = tonumber(ARGV[3]), tonumber(ARGV[4])

            redis.call('zadd', candidates, 'NX', pipeline_id, member)
            redis.call('zremrangebyrank', candidates, 0, -max_size - 1)
            redis.call('expire', candidates, ttl)
          LUA

          def initialize(redis_key:, ttl:, redis: Gitlab::Redis::SharedState)
            @redis_key = redis_key
            @ttl = ttl
            @redis = redis
          end

          def register(key, max_size:)
            eval_script(REGISTER, [key.pipeline_id, key.to_s, ttl, max_size])
          end

          def claim_before(key, limit:)
            pipeline_keys(eval_script(CLAIM, [key.pipeline_id, limit]))
          end

          def delete(key)
            with_redis { |redis| redis.zrem(redis_key, key.to_s) }
          end

          def registered?(key)
            with_redis { |redis| redis.zscore(redis_key, key.to_s) }.present?
          end

          def count
            with_redis { |redis| redis.zcard(redis_key) }.to_i
          end

          private

          attr_reader :redis_key, :ttl, :redis

          def eval_script(script, argv)
            with_redis { |connection| script.eval(connection, keys: [redis_key], argv: argv) }
          end

          def pipeline_keys(members)
            Array(members).map { |member| PipelineKey.parse(member) }
          end

          def with_redis(&block)
            redis.with(&block) # rubocop:disable CodeReuse/ActiveRecord -- a redis pool, not AR
          end
        end
      end
    end
  end
end
