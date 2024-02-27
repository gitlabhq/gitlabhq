# frozen_string_literal: true

module LimitedCapacity
  class JobTracker # rubocop:disable Scalability/IdempotentWorker
    include Gitlab::Utils::StrongMemoize

    LUA_REGISTER_SCRIPT = <<~EOS
      local set_key, element, max_elements = KEYS[1], ARGV[1], ARGV[2]

      if redis.call("scard", set_key) < tonumber(max_elements) then
        redis.call("sadd", set_key, element)
        return true
      end

      return false
    EOS

    def initialize(namespace)
      @namespace = namespace
    end

    def register(jid, max_jids)
      with_redis do |redis|
        redis.eval(LUA_REGISTER_SCRIPT, keys: [counter_key], argv: [jid.to_s, max_jids.to_i])
      end.present?
    end

    def remove(jid)
      with_redis do |redis|
        remove_job_keys(redis, jid)
      end
    end

    def clean_up
      completed_jids = Gitlab::SidekiqStatus.completed_jids(running_jids)
      return unless completed_jids.any?

      with_redis do |redis|
        remove_job_keys(redis, completed_jids)
      end
    end

    def count
      with_redis { |redis| redis.scard(counter_key) }
    end

    def running_jids
      with_redis do |redis|
        redis.smembers(counter_key)
      end
    end

    private

    attr_reader :namespace

    def counter_key
      "worker:#{namespace.to_s.underscore}:running"
    end

    def remove_job_keys(redis, keys)
      redis.srem?(counter_key, keys) if keys.present?
    end

    def with_redis(&block)
      Gitlab::Redis::SharedState.with(&block) # rubocop: disable CodeReuse/ActiveRecord
    end
  end
end
