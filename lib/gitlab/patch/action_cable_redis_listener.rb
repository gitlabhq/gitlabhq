# frozen_string_literal: true

# Modifies https://github.com/rails/rails/blob/v6.1.4.6/actioncable/lib/action_cable/subscription_adapter/redis.rb
# so that it is resilient to Redis connection errors.
# See https://github.com/rails/rails/issues/27659.

# rubocop:disable Gitlab/ModuleWithInstanceVariables
module Gitlab
  module Patch
    module ActionCableRedisListener
      private

      def ensure_listener_running
        @thread ||= Thread.new do
          Thread.current.abort_on_exception = true

          conn = @adapter.redis_connection_for_subscriptions
          listen conn
        rescue ::Redis::BaseConnectionError
          @thread = @raw_client = nil
          ::ActionCable.server.restart
        end
      end
    end
  end
end
