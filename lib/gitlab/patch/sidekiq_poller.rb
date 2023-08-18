# frozen_string_literal: true

module Gitlab
  module Patch
    module SidekiqPoller
      def enqueue
        Rails.application.reloader.wrap do
          ::Gitlab::SafeRequestStore.ensure_request_store do
            super
          ensure
            ::Gitlab::Database::LoadBalancing.release_hosts
          end
        end
      end
    end
  end
end
