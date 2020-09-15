# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module DuplicateJobs
      class Client
        def call(worker_class, job, queue, _redis_pool, &block)
          ::Gitlab::SidekiqMiddleware::DuplicateJobs::DuplicateJob.new(job, queue).schedule(&block)
        end
      end
    end
  end
end
