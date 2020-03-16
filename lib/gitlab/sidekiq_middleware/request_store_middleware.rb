# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    class RequestStoreMiddleware
      include Gitlab::WithRequestStore

      def call(worker, job, queue)
        with_request_store do
          yield
        end
      end
    end
  end
end
