# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module PauseControl
      class Server
        def call(worker_class, job, _queue, &block)
          ::Gitlab::SidekiqMiddleware::PauseControl::StrategyHandler.new(worker_class, job).perform(&block)
        end
      end
    end
  end
end
