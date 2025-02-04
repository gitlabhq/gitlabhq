# frozen_string_literal: true

module Gitlab
  module Redis
    class HLL
      BATCH_SIZE = 300
      KEY_REGEX = %r{\A(\w|-|:)*\{\w*\}(\w|-|:|\[|,|\])*\z}
      KeyFormatError = Class.new(StandardError)

      def self.count(params)
        self.new.count(**params)
      end

      def self.add(params)
        self.new.add(**params)
      end

      def count(keys:)
        Gitlab::Redis::SharedState.with do |redis|
          redis.pfcount(*keys)
        end
      end

      # Check a basic format for the Redis key in order to ensure the keys are in the same hash slot
      #
      # Examples of keys
      #   project:{1}:set_a
      #   project:{1}:set_b
      #   project:{2}:set_c
      #   2020-216-{project_action}
      #   i_{analytics}_dev_ops_score-2020-32
      def add(key:, value:, expiry:)
        validate_key!(key)

        Gitlab::Redis::SharedState.with do |redis|
          redis.multi do |multi|
            Array.wrap(value).each_slice(BATCH_SIZE) { |batch| multi.pfadd(key, batch) }

            multi.expire(key, expiry)
          end
        end
      end

      private

      def validate_key!(key)
        return if KEY_REGEX.match?(key)

        raise KeyFormatError, "Invalid key format. #{key} key should have changeable parts in curly braces. See https://docs.gitlab.com/ee/development/redis.html#multi-key-commands"
      end
    end
  end
end
