# frozen_string_literal: true

module Gitlab
  module Redis
    module SessionsStoreHelper
      extend ActiveSupport::Concern

      module StoreMethods
        def redis_store_class
          use_redis_session_store? ? Gitlab::Redis::Sessions : Gitlab::Redis::SharedState
        end

        private

        def use_redis_session_store?
          Gitlab::Utils.to_boolean(ENV['GITLAB_USE_REDIS_SESSIONS_STORE'], default: true)
        end
      end

      include StoreMethods

      included do
        extend StoreMethods
      end
    end
  end
end
