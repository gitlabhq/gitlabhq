# frozen_string_literal: true

module Gitlab
  module Redis
    class Workhorse < ::Gitlab::Redis::Wrapper
      class << self
        def config_fallback
          SharedState
        end

        private

        def redis
          primary_store = ::Redis.new(params)
          secondary_store = ::Redis.new(config_fallback.params)

          MultiStore.new(primary_store, secondary_store, store_name)
        end
      end
    end
  end
end
