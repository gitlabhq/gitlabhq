# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module ConcurrencyLimit
      class Server
        def call(worker, job, _queue, &block)
          ::Gitlab::SidekiqMiddleware::ConcurrencyLimit::Middleware.new(worker, job).perform(&block)
        end
      end
    end
  end
end
