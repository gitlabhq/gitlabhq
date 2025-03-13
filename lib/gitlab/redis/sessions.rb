# frozen_string_literal: true

module Gitlab
  module Redis
    class Sessions < ::Gitlab::Redis::MultiStoreWrapper
      SESSION_NAMESPACE = 'session:gitlab'
      USER_SESSIONS_NAMESPACE = 'session:user:gitlab'
      USER_SESSIONS_LOOKUP_NAMESPACE = 'session:lookup:user:gitlab'
      IP_SESSIONS_LOOKUP_NAMESPACE = 'session:lookup:ip:gitlab2'
      OTP_SESSIONS_NAMESPACE = 'session:otp'

      # The data we store on Sessions used to be stored on SharedState.
      def self.config_fallback
        SharedState
      end

      def self.multistore
        MultiStore.create_using_pool(ClusterSessions.pool, pool, store_name)
      end
    end
  end
end
