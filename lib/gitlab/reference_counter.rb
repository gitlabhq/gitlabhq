# frozen_string_literal: true

module Gitlab
  # Reference Counter
  #
  # A reference counter is used as a mechanism to identify when
  # a repository is being accessed by a writable operation.
  #
  # Maintenance operations would use this as a clue to when it should
  # execute significant changes in order to avoid disrupting running traffic
  class ReferenceCounter
    REFERENCE_EXPIRE_TIME = 600

    attr_reader :gl_repository, :key

    # Reference Counter instance
    #
    # @example
    #   Gitlab::ReferenceCounter.new('project-1')
    #
    # @see Gitlab::GlRepository::RepoType.identifier_for_repositorable
    # @param [String] gl_repository repository identifier
    def initialize(gl_repository)
      @gl_repository = gl_repository
      @key = "git-receive-pack-reference-counter:#{gl_repository}"
    end

    # Return the actual counter value
    #
    # @return [Integer] value
    def value
      Gitlab::Redis::SharedState.with do |redis|
        (redis.get(key) || 0).to_i
      end
    end

    # Increase the counter
    #
    # @return [Boolean] whether operation was a success
    def increase
      redis_cmd do |redis|
        redis.incr(key)
        redis.expire(key, REFERENCE_EXPIRE_TIME)
      end
    end

    # Decrease the counter
    #
    # @return [Boolean] whether operation was a success
    def decrease
      redis_cmd do |redis|
        current_value = redis.decr(key)
        if current_value < 0
          Gitlab::AppLogger.warn("Reference counter for #{gl_repository} decreased " \
            "when its value was less than 1. Resetting the counter.")
          redis.del(key)
        end
      end
    end

    # Reset the reference counter
    #
    # @private Used internally by SRE and debugging purpose
    # @return [Boolean] whether reset was a success
    def reset!
      redis_cmd do |redis|
        redis.del(key)
      end
    end

    # When the reference counter would expire
    #
    # @api private Used internally by SRE and debugging purpose
    # @return [Integer] Number in seconds until expiration or false if never
    def expires_in
      Gitlab::Redis::SharedState.with do |redis|
        redis.ttl(key)
      end
    end

    private

    def redis_cmd
      Gitlab::Redis::SharedState.with { |redis| yield(redis) }

      true
    rescue StandardError => e
      Gitlab::AppLogger.warn("GitLab: An unexpected error occurred in writing to Redis: #{e}")

      false
    end
  end
end
