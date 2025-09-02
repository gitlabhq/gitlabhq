# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module ConcurrencyLimit
      class Server
        def call(worker, job, _queue, &block)
          if Feature.enabled?(:sidekiq_concurrency_limit_middleware_v2, Feature.current_request)
            ::Gitlab::SidekiqMiddleware::ConcurrencyLimit::MiddlewareV2.new(worker, job).perform(&block)
          else
            ::Gitlab::SidekiqMiddleware::ConcurrencyLimit::Middleware.new(worker, job).perform(&block)
          end
        end
      end
    end
  end
end
