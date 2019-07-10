# frozen_string_literal: true

module Gitlab
  class ReferenceCounter
    REFERENCE_EXPIRE_TIME = 600

    attr_reader :gl_repository, :key

    def initialize(gl_repository)
      @gl_repository = gl_repository
      @key = "git-receive-pack-reference-counter:#{gl_repository}"
    end

    def value
      Gitlab::Redis::SharedState.with { |redis| (redis.get(key) || 0).to_i }
    end

    def increase
      redis_cmd do |redis|
        redis.incr(key)
        redis.expire(key, REFERENCE_EXPIRE_TIME)
      end
    end

    # rubocop:disable Gitlab/RailsLogger
    def decrease
      redis_cmd do |redis|
        current_value = redis.decr(key)
        if current_value < 0
          Rails.logger.warn("Reference counter for #{gl_repository} decreased" \
            " when its value was less than 1. Reseting the counter.")
          redis.del(key)
        end
      end
    end
    # rubocop:enable Gitlab/RailsLogger

    private

    def redis_cmd
      Gitlab::Redis::SharedState.with { |redis| yield(redis) }
      true
    rescue => e
      Rails.logger.warn("GitLab: An unexpected error occurred in writing to Redis: #{e}") # rubocop:disable Gitlab/RailsLogger
      false
    end
  end
end
