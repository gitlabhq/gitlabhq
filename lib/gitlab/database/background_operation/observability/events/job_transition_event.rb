# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundOperation
      module Observability
        module Events
          # Event responsible for logging any job state transition event
          # E.g: from => running, to => failed, with => StandardError: timeout
          class JobTransitionEvent < Event
            LOG_EVENT = 'background_operation_job_transition_event'

            def payload
              worker = record.worker
              previous_state, new_state, error = attributes.values_at(:previous_state, :new_state, :error)

              {
                message: LOG_EVENT,
                previous_state: previous_state,
                new_state: new_state,
                worker_id: record.worker_id,
                worker_partition: record.worker_partition,
                job_class_name: worker.job_class_name,
                batch_class_name: worker.batch_class_name,
                table_name: worker.table_name,
                column_name: worker.column_name,
                attempts: record.attempts,
                exception_class: error&.class,
                exception_message: error&.message
              }
            end
          end
        end
      end
    end
  end
end
