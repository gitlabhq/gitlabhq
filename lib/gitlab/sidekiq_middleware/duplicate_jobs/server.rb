# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module DuplicateJobs
      class Server
        def call(worker, job, queue, &block)
          ::Gitlab::SidekiqMiddleware::DuplicateJobs::DuplicateJob.new(job, queue).perform(&block)
        end
      end
    end
  end
end
