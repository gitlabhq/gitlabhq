# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundOperation
      class Runner
        def initialize(connection:, executor: Executor.new(connection: connection))
          @connection = connection
          @executor = executor
        end

        def run_operation_job(worker)
          next_job = find_or_create_next_job(worker)
          return finish_active_operation(worker) unless next_job

          execute_job_and_handle_failure(worker, next_job)
        end

        private

        attr_reader :connection, :executor

        def execute_job_and_handle_failure(worker, job)
          executor.perform(job)
          adjust_operation(worker)

          return unless job.failed? && worker.should_stop?

          worker.failure!
        end

        def find_or_create_next_job(worker)
          next_batch_min, next_batch_max = find_next_batch_range(worker)

          return worker.jobs.retriable.first if next_batch_min.nil? || next_batch_max.nil?

          worker.create_job!(next_batch_min, next_batch_max)
        end

        def find_next_batch_range(worker)
          batching_strategy = batching_strategy_for(worker)
          batch_min_value = worker.next_min_cursor

          next_batch_bounds = batching_strategy.next_batch(
            worker.table_name,
            batch_min_value: batch_min_value,
            batch_size: worker.batch_size,
            job_class: worker.job_class
          )

          return if next_batch_bounds.nil?

          clamped_batch_range(worker, next_batch_bounds)
        end

        def batching_strategy_for(worker)
          worker.batch_class.new(connection: connection)
        end

        def clamped_batch_range(worker, next_bounds)
          next_min, next_max = next_bounds
          max_cursor = worker.max_cursor

          return if cursor_greater_than?(next_min, max_cursor)

          next_max = cursor_min(next_max, max_cursor)
          [next_min, next_max]
        end

        def finish_active_operation(worker)
          return if worker.jobs.running.exists?

          if worker.jobs.failed.exists?
            worker.failure!
          else
            worker.finish!
          end
        end

        def cursor_greater_than?(cursor1, cursor2)
          (cursor1 <=> cursor2) > 0
        end

        def cursor_min(cursor1, cursor2)
          (cursor1 <=> cursor2) <= 0 ? cursor1 : cursor2
        end

        def adjust_operation(worker)
          signals = Gitlab::Database::HealthStatus.evaluate(worker.health_context)

          if signals.any?(&:stop?)
            worker.hold!
          else
            worker.optimize!
          end
        end
      end
    end
  end
end
