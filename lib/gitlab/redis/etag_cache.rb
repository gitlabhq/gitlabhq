# frozen_string_literal: true

module Gitlab
  module Redis
    class EtagCache < ::Gitlab::Redis::Wrapper
      class << self
        def store_name
          'Cache'
        end

        private

        def redis
          primary_store = ::Redis.new(Gitlab::Redis::Cache.params)
          secondary_store = ::Redis.new(Gitlab::Redis::SharedState.params)

          MultiStore.new(primary_store, secondary_store, name.demodulize)
        end
      end
    end
  end
end
