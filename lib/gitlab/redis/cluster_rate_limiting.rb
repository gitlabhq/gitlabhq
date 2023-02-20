# frozen_string_literal: true

module Gitlab
  module Redis
    class ClusterRateLimiting < ::Gitlab::Redis::Wrapper
      def self.config_fallback
        Cache
      end
    end
  end
end
