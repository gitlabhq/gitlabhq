# frozen_string_literal: true

module Ci
  module BuildTraceChunks
    class RedisBase
      CHUNK_REDIS_TTL = 1.week
      LUA_APPEND_CHUNK = <<~EOS
        local key, new_data, offset = KEYS[1], ARGV[1], ARGV[2]
        local length = new_data:len()
        local expire = #{CHUNK_REDIS_TTL.seconds}
        local current_size = redis.call("strlen", key)
        offset = tonumber(offset)

        if offset == 0 then
          -- overwrite everything
          redis.call("set", key, new_data, "ex", expire)
          return redis.call("strlen", key)
        elseif offset > current_size then
          -- offset range violation
          return -1
        elseif offset + length >= current_size then
          -- efficiently append or overwrite and append
          redis.call("expire", key, expire)
          return redis.call("setrange", key, offset, new_data)
        else
          -- append and truncate
          local current_data = redis.call("get", key)
          new_data = current_data:sub(1, offset) .. new_data
          redis.call("set", key, new_data, "ex", expire)
          return redis.call("strlen", key)
        end
      EOS

      def data(model)
        with_redis do |redis|
          redis.get(key(model))
        end
      end

      def set_data(model, new_data)
        with_redis do |redis|
          redis.set(key(model), new_data, ex: CHUNK_REDIS_TTL)
        end
      end

      def append_data(model, new_data, offset)
        with_redis do |redis|
          redis.eval(LUA_APPEND_CHUNK, keys: [key(model)], argv: [new_data, offset])
        end
      end

      def size(model)
        with_redis do |redis|
          redis.strlen(key(model))
        end
      end

      def delete_data(model)
        delete_keys([[model.build_id, model.chunk_index]])
      end

      def keys(relation)
        relation.pluck(:build_id, :chunk_index)
      end

      def delete_keys(keys)
        return if keys.empty?

        keys = keys.map { |key| key_raw(*key) }

        with_redis do |redis|
          # https://gitlab.com/gitlab-org/gitlab/-/issues/224171
          Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
            if Gitlab::Redis::ClusterUtil.cluster?(redis)
              Gitlab::Redis::ClusterUtil.batch_unlink(keys, redis)
            else
              redis.del(keys)
            end
          end
        end
      end

      private

      def key(model)
        key_raw(model.build_id, model.chunk_index)
      end

      def key_raw(build_id, chunk_index)
        "gitlab:ci:trace:#{build_id.to_i}:chunks:#{chunk_index.to_i}"
      end
    end
  end
end
