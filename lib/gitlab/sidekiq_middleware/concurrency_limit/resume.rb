# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module ConcurrencyLimit
      class Resume
        EmptyJobMetadataError = Class.new(StandardError)

        # This middleware updates the job payload with stored context and additional information needed by the
        # SidekiqMiddleware::ConcurrencyLimit::Middleware to resume the job.
        def call(worker_class_or_name, job, _queue, _redis_pool, &)
          worker_name = worker_class_or_name.is_a?(Class) ? worker_class_or_name.name : worker_class_or_name
          return yield unless worker_name

          # metadata is written in QueueManager#bulk_send_to_processing_queue
          metadata_queue = Gitlab::SafeRequestStore[metadata_key(worker_name)]
          return yield if metadata_queue.nil?

          if metadata_queue.empty?
            Gitlab::ErrorTracking.track_exception(
              EmptyJobMetadataError.new("Missing job metadata from ConcurrencyLimit::ResumeWorker"))
            return yield
          end

          job.merge!(metadata_queue.pop)
          yield
        end

        def metadata_key(worker_name)
          Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService.metadata_key(worker_name)
        end
      end
    end
  end
end
