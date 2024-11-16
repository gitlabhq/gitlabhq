# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module ResourceUsageLimit
      class Server
        def call(worker, job, _queue, &)
          Gitlab::SidekiqMiddleware::ResourceUsageLimit::Middleware.new(worker, job).perform(&)
        end
      end
    end
  end
end
