# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module ConcurrencyLimit
      class Client
        def call(worker_class, job, _queue, _redis_pool, &block)
          if Feature.enabled?(:sidekiq_concurrency_limit_middleware_v2, Feature.current_request)
            ::Gitlab::SidekiqMiddleware::ConcurrencyLimit::MiddlewareV2.new(worker_class, job).schedule(&block)
          else
            ::Gitlab::SidekiqMiddleware::ConcurrencyLimit::Middleware.new(worker_class, job).schedule(&block)
          end
        end
      end
    end
  end
end
