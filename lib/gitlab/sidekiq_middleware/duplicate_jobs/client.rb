# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module DuplicateJobs
      class Client
        def call(worker_class, job, queue, _redis_pool, &block)
          # We don't try to deduplicate jobs that are scheduled in the future
          return yield if job['at']

          DuplicateJob.new(job, queue).schedule(&block)
        end
      end
    end
  end
end
