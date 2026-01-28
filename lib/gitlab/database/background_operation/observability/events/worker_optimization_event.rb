# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundOperation
      module Observability
        module Events
          # Event responsible for logging batch size optimization events
          # E.g: from => 1_000, to => 15_000
          class WorkerOptimizationEvent < Event
            LOG_EVENT = 'background_operation_worker_optimization_event'

            def payload
              old_batch_size, new_batch_size = attributes.values_at(:old_batch_size, :new_batch_size)

              {
                message: LOG_EVENT,
                old_batch_size: old_batch_size,
                new_batch_size: new_batch_size,
                on_hold_until: record.on_hold_until,
                priority: record.priority,
                job_class_name: record.job_class_name,
                batch_class_name: record.batch_class_name,
                table_name: record.table_name,
                column_name: record.column_name,
                gitlab_schema: record.gitlab_schema,
                job_arguments: record.job_arguments
              }
            end
          end
        end
      end
    end
  end
end
