# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundOperation
      module Observability
        module Events
          # Event responsible for logging any worker state transition event
          # E.g: from => pending, to => running
          class WorkerTransitionEvent < Event
            LOG_EVENT = 'background_operation_worker_transition_event'

            def payload
              previous_state, new_state = attributes.values_at(:previous_state, :new_state)

              {
                message: LOG_EVENT,
                previous_state: previous_state,
                new_state: new_state,
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
