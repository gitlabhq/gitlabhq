# frozen_string_literal: true
module LimitedCapacity
  class JobTracker # rubocop:disable Scalability/IdempotentWorker
    include Gitlab::Utils::StrongMemoize

    def initialize(namespace)
      @namespace = namespace
    end

    def register(jid)
      _added, @count = with_redis_pipeline do |redis|
        register_job_keys(redis, jid)
        get_job_count(redis)
      end
    end

    def remove(jid)
      _removed, @count = with_redis_pipeline do |redis|
        remove_job_keys(redis, jid)
        get_job_count(redis)
      end
    end

    def clean_up
      completed_jids = Gitlab::SidekiqStatus.completed_jids(running_jids)
      return unless completed_jids.any?

      _removed, @count = with_redis_pipeline do |redis|
        remove_job_keys(redis, completed_jids)
        get_job_count(redis)
      end
    end

    def count
      @count ||= with_redis { |redis| get_job_count(redis) }
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

    def get_job_count(redis)
      redis.scard(counter_key)
    end

    def register_job_keys(redis, keys)
      redis.sadd(counter_key, keys)
    end

    def remove_job_keys(redis, keys)
      redis.srem(counter_key, keys)
    end

    def with_redis(&block)
      Gitlab::Redis::Queues.with(&block) # rubocop: disable CodeReuse/ActiveRecord
    end

    def with_redis_pipeline(&block)
      with_redis do |redis|
        redis.pipelined(&block)
      end
    end
  end
end
