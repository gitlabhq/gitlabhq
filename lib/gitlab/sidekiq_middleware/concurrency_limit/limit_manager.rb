# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module ConcurrencyLimit
      class LimitManager
        include Gitlab::Utils::StrongMemoize

        TTL = 30.minutes
        attr_reader :worker_name

        def initialize(worker_name:, prefix:)
          @worker_name = worker_name
          @prefix = prefix
        end

        # Reads the current limit value in Redis.
        # Falls back on the max limit value set by default in `worker.get_concurrency_limit`
        # if no limit is set in Redis.
        # @return [Integer] The current limit value, or 0 if no limit is set
        def current_limit
          return 0 if worker_klass.nil?

          value = with_redis do |r|
            value = r.get(current_limit_key)
            value.to_i if value
          end

          return value unless value.nil?

          default_limit
        end

        # Updates the current limit value in Redis
        # @param value [Integer] The new limit value to set
        def set_current_limit!(value)
          with_redis do |r|
            r.set(current_limit_key, value.to_i, ex: TTL)
          end
        end

        private

        def worker_klass
          worker_name.safe_constantize
        end
        strong_memoize_attr(:worker_klass)

        def default_limit
          worker_klass.respond_to?(:get_concurrency_limit) ? worker_klass.get_concurrency_limit : 0
        end

        def with_redis(&block)
          Gitlab::Redis::QueuesMetadata.with(&block) # rubocop:disable CodeReuse/ActiveRecord -- Not active record
        end

        def current_limit_key
          "#{@prefix}:{#{@worker_name.underscore}}:current_limit"
        end
      end
    end
  end
end
