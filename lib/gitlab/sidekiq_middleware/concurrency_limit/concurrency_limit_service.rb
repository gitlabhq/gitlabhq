# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module ConcurrencyLimit
      class ConcurrencyLimitService
        REDIS_KEY_PREFIX = 'sidekiq:concurrency_limit'

        delegate :add_to_queue!, :queue_size, :metadata_key, :has_jobs_in_queue?, :resume_processing!,
          to: :@queue_manager

        delegate :track_execution_start, :track_execution_end, :cleanup_stale_trackers,
          :concurrent_worker_count, to: :@worker_execution_tracker

        def initialize(worker_name)
          @worker_name = worker_name
          @queue_manager = QueueManager.new(worker_name: worker_name, prefix: REDIS_KEY_PREFIX)
          @worker_execution_tracker = WorkerExecutionTracker.new(worker_name: worker_name, prefix: REDIS_KEY_PREFIX)
        end

        class << self
          def add_to_queue!(job, context)
            new(job['class']).add_to_queue!(job, context)
          end

          def has_jobs_in_queue?(worker_name)
            new(worker_name).has_jobs_in_queue?
          end

          def resume_processing!(worker_name, limit:)
            new(worker_name).resume_processing!(limit: limit)
          end

          def queue_size(worker_name)
            new(worker_name).queue_size
          end

          def metadata_key(worker_name)
            new(worker_name).metadata_key
          end

          def cleanup_stale_trackers(worker_name)
            new(worker_name).cleanup_stale_trackers
          end

          def track_execution_start(worker_name)
            new(worker_name).track_execution_start
          end

          def track_execution_end(worker_name)
            new(worker_name).track_execution_end
          end

          def concurrent_worker_count(worker_name)
            new(worker_name).concurrent_worker_count
          end
        end
      end
    end
  end
end
