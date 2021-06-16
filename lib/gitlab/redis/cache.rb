# frozen_string_literal: true

module Gitlab
  module Redis
    class Cache < ::Gitlab::Redis::Wrapper
      CACHE_NAMESPACE = 'cache:gitlab'

      private

      def raw_config_hash
        config = super
        config[:url] = 'redis://localhost:6380' if config[:url].blank?
        config
      end
    end
  end
end
