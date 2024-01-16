# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module ConcurrencyLimit
      class Client
        def call(worker_class, job, _queue, _redis_pool, &block)
          ::Gitlab::SidekiqMiddleware::ConcurrencyLimit::Middleware.new(worker_class, job).schedule(&block)
        end
      end
    end
  end
end
