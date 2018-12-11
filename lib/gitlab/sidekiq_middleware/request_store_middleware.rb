# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    class RequestStoreMiddleware
      def call(worker, job, queue)
        RequestStore.begin!
        yield
      ensure
        RequestStore.end!
        RequestStore.clear!
      end
    end
  end
end
