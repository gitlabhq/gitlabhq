# frozen_string_literal: true

# rubocop:disable Gitlab/NamespacedClass -- generic code
# rubocop:disable Gitlab/BoundedContexts -- generic code
class IdempotencyCache
  # When code is wrapped with ensure_idempotency it won't be
  # called again within the TTL(time to live) for the same key
  # if the operation was successful completed
  #
  # Example:
  # IdempotencyCache.ensure_idempotency("tracking_cache:#{build_id}", 5.hours)
  #   # idempotent within the TTL
  #   # wont run again if it ran successfully for that build within 5 hours
  #   track(params)
  # end
  def self.ensure_idempotency(key, ttl)
    return if already_completed?(key)

    result = yield

    new(key, ttl).mark_as_completed!

    result
  end

  def self.already_completed?(key)
    Gitlab::Redis::SharedState.with do |redis|
      redis.exists?(key) # rubocop:disable CodeReuse/ActiveRecord  -- not active record
    end
  end

  def initialize(key, ttl)
    @key = key
    @ttl = ttl
  end

  def mark_as_completed!
    Gitlab::Redis::SharedState.with do |redis|
      redis.set(
        @key,
        1,
        ex: @ttl
      )
    end
  end
end
# rubocop:enable Gitlab/NamespacedClass
# rubocop:enable Gitlab/BoundedContexts
