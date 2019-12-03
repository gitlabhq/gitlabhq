# frozen_string_literal: true

# Adapted from https://github.com/peek/peek/blob/master/lib/peek/adapters/redis.rb
module Gitlab
  module PerformanceBar
    module RedisAdapterWhenPeekEnabled
      def save(request_id)
        super if ::Gitlab::PerformanceBar.enabled_for_request?
      end
    end
  end
end
