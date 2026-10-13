# frozen_string_literal: true

module Gitlab
  module Ci
    module RedundantPipelines
      class CandidateCache
        # Redis access for CandidateCache. Speaks pipeline keys, so its owner never
        # handles Redis members.
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

          # Scored by pipeline id, so the trim drops the oldest pipelines first.
          #   ARGV[1] pipeline_id, ARGV[2] member, ARGV[3] ttl, ARGV[4] max_size
          ADD = ::Labkit::Redis::Script.new(<<~LUA)
            local set = KEYS[1]
            local pipeline_id, member = tonumber(ARGV[1]), ARGV[2]
            local ttl, max_size = tonumber(ARGV[3]), tonumber(ARGV[4])

            local added = redis.call('zadd', set, 'NX', pipeline_id, member)
            redis.call('zremrangebyrank', set, 0, -max_size - 1)
            redis.call('expire', set, ttl)

            return added
          LUA

          def initialize(prefix:, ttl:, max_size:, redis: Gitlab::Redis::SharedState)
            @prefix = prefix
            @ttl = ttl
            @max_size = max_size
            @redis = redis
          end

          def register(key)
            add_to(candidates_key, key)
          end

          def protect(key)
            added = add_to(protected_key, key) == 1

            yield if added && block_given?
          end

          def claim_before(key, limit:)
            pipeline_keys(eval_script(CLAIM, candidates_key, [key.pipeline_id, limit]))
          end

          def delete(key)
            with_redis { |redis| redis.zrem(candidates_key, key.to_s) }
          end

          def registered?(key)
            scored?(candidates_key, key)
          end

          def protected?(key)
            scored?(protected_key, key)
          end

          def count
            with_redis { |redis| redis.zcard(candidates_key) }.to_i
          end

          private

          attr_reader :prefix, :ttl, :max_size, :redis

          def candidates_key
            "#{prefix}:candidates"
          end

          def protected_key
            "#{prefix}:protected"
          end

          def add_to(set, key)
            eval_script(ADD, set, [key.pipeline_id, key.to_s, ttl, max_size])
          end

          def scored?(set, key)
            with_redis { |redis| redis.zscore(set, key.to_s) }.present?
          end

          def eval_script(script, set, argv)
            with_redis { |connection| script.eval(connection, keys: [set], argv: argv) }
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
