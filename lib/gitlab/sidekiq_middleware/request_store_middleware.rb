# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    class RequestStoreMiddleware
      def call(worker, job, queue)
        ::Gitlab::SafeRequestStore.ensure_request_store do
          yield
        end
      end
    end
  end
end
