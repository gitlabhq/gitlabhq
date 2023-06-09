# frozen_string_literal: true

module Gitlab
  class AvatarCache
    class << self
      # Increment this if a breaking change requires
      # immediate cache expiry of all avatar caches.
      #
      # @return [Integer]
      VERSION = 2

      # @return [Symbol]
      BASE_KEY = :avatar_cache

      # @return [ActiveSupport::Duration]
      DEFAULT_EXPIRY = 7.days

      # Look up cached avatar data by email address.
      # This accepts a block to provide the value to be
      # cached in the event nothing is found.
      #
      # Multiple calls in the same request will be served from the
      # request store.
      #
      # @param email [String]
      # @param additional_keys [*Object] all must respond to `#to_s`
      # @param expires_in [ActiveSupport::Duration, Integer]
      # @yield [email, *additional_keys] yields the supplied params back to the block
      # @return [String]
      def by_email(email, *additional_keys, expires_in: DEFAULT_EXPIRY)
        key = email_key(email)
        subkey = additional_keys.join(":")

        Gitlab::SafeRequestStore.fetch([key, subkey]) do
          with do |redis|
            # Look for existing cache value
            cached = redis.hget(key, subkey)

            # Return the cached entry if set
            break cached unless cached.nil?

            # Otherwise, call the block to get the value
            to_cache = yield(email, *additional_keys).to_s

            # Set it in the cache
            redis.hset(key, subkey, to_cache)

            # Update the expiry time
            redis.expire(key, expires_in)

            # Return this new value
            break to_cache
          end
        end
      end

      # Remove one or more emails from the cache
      #
      # @param emails [String] one or more emails to delete
      # @return [Integer] the number of keys deleted
      def delete_by_email(*emails)
        return 0 if emails.empty?

        with do |redis|
          keys = emails.map { |email| email_key(email) }

          Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
            if Gitlab::Redis::ClusterUtil.cluster?(redis)
              Gitlab::Redis::ClusterUtil.batch_unlink(keys, redis)
            else
              redis.unlink(*keys)
            end
          end
        end
      end

      private

      # @param email [String]
      # @return [String]
      def email_key(email)
        "#{BASE_KEY}:v#{VERSION}:#{email}"
      end

      def with(&blk)
        Gitlab::Redis::Cache.with(&blk) # rubocop:disable CodeReuse/ActiveRecord
      end
    end
  end
end
