# frozen_string_literal: true

module Gitlab
  module Redis
    class HLL
      def self.count(params)
        self.new.count(params)
      end

      def self.add(params)
        self.new.add(params)
      end

      # NOTE: It is important to make sure the keys are in the same hash slot
      # https://redis.io/topics/cluster-spec#keys-hash-tags
      def count(keys:)
        Gitlab::Redis::SharedState.with do |redis|
          redis.pfcount(*keys)
        end
      end

      def add(key:, value:, expiry:)
        Gitlab::Redis::SharedState.with do |redis|
          redis.multi do |multi|
            multi.pfadd(key, value)
            multi.expire(key, expiry)
          end
        end
      end
    end
  end
end
