# frozen_string_literal: true

module Gitlab
  module Redis
    class Cache < ::Gitlab::Redis::Wrapper
      CACHE_NAMESPACE = 'cache:gitlab'

      class << self
        def default_url
          'redis://localhost:6380'
        end
      end
    end
  end
end
