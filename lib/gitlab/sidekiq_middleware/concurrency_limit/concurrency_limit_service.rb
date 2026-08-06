# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module ConcurrencyLimit
      class ConcurrencyLimitService
        REDIS_KEY_PREFIX = 'sidekiq:concurrency_limit'

        delegate :add_to_queue!, :drop_jobs!, :queue_size, :metadata_key, :has_jobs_in_queue?, :resume_processing!,
          to: :@queue_manager

        delegate :track_execution_start, :track_execution_end, :cleanup_stale_trackers,
          :concurrent_worker_count, :track_pending_resumed_jobs, :untrack_pending_resumed_job,
          :pending_resumed_jobs_count, to: :@worker_execution_tracker

        delegate :current_limit, :set_current_limit!, to: :@limit_manager

        def initialize(worker_name)
          @worker_name = worker_name
          @queue_manager = QueueManager.new(worker_name: worker_name, prefix: REDIS_KEY_PREFIX)
          @worker_execution_tracker = WorkerExecutionTracker.new(worker_name: worker_name, prefix: REDIS_KEY_PREFIX)
          @limit_manager = LimitManager.new(worker_name: worker_name, prefix: REDIS_KEY_PREFIX)
        end

        class << self
          def add_to_queue!(job, context)
            new(job['class']).add_to_queue!(job, context)
          end

          # Removes deferred jobs matching the metadata across the given workers' queues.
          #
          # @param worker_names [Array<String>] worker class names whose deferred queues to purge
          # @param context_metadata [Hash] application-context metadata to match
          # @param timeout [Numeric] seconds budget shared across all the workers' queues
          # @return [Hash] :completed flag (false if any queue timed out) and :deleted_jobs count
          # @see QueueManager#drop_jobs!
          def drop_matching_jobs!(worker_names, context_metadata, timeout: 30)
            return { completed: true, deleted_jobs: 0 } if worker_names.empty? || context_metadata.empty?

            start_time = Gitlab::Metrics::System.monotonic_time
            completed = true
            deleted = 0

            worker_names.each do |worker_name|
              remaining = timeout - (Gitlab::Metrics::System.monotonic_time - start_time)
              if remaining <= 0
                completed = false
                break
              end

              result = new(worker_name).drop_jobs!(context_metadata, timeout: remaining)
              deleted += result[:deleted_jobs]
              completed &&= result[:completed]
            end

            { completed: completed, deleted_jobs: deleted }
          end

          def has_jobs_in_queue?(worker_name)
            new(worker_name).has_jobs_in_queue?
          end

          def resume_processing!(worker_name)
            new(worker_name).resume_processing!
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

          def track_pending_resumed_jobs(worker_name, count)
            new(worker_name).track_pending_resumed_jobs(count)
          end

          def untrack_pending_resumed_job(worker_name, count = 1)
            new(worker_name).untrack_pending_resumed_job(count)
          end

          def pending_resumed_jobs_count(worker_name)
            new(worker_name).pending_resumed_jobs_count
          end

          def current_limit(worker_name)
            new(worker_name).current_limit
          end

          def set_current_limit!(worker_name, limit:)
            new(worker_name).set_current_limit!(limit)
          end

          def over_the_limit?(worker_name)
            service = new(worker_name)
            limit = service.current_limit

            return false if limit == 0

            service.concurrent_worker_count >= limit
          end
        end
      end
    end
  end
end
