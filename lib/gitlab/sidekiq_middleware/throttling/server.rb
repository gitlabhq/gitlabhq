# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module Throttling
      class Server
        def call(worker_class, _job, _queue, &block)
          ::Gitlab::SidekiqMiddleware::Throttling::Middleware.new(worker_class).perform(&block)
        end
      end
    end
  end
end
