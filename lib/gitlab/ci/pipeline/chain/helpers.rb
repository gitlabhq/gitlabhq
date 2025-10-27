# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Helpers
          def error(message, failure_reason: nil)
            sanitized_message = sanitize_message(message)
            pipeline.add_error_message(sanitized_message)

            handle_pipeline_failure(failure_reason)

            # TODO: consider not to rely on AR errors directly as they can be
            # polluted with other unrelated errors (e.g. state machine)
            # https://gitlab.com/gitlab-org/gitlab/-/issues/220823
            pipeline.errors.add(:base, sanitized_message)

            pipeline.errors.full_messages
          end

          def warning(message)
            pipeline.add_warning_message(sanitize_message(message))
          end

          private

          def sanitize_message(message)
            ActionController::Base.helpers.sanitize(message, tags: [])
          end

          def handle_pipeline_failure(failure_reason)
            if should_persist_pipeline_failure?(failure_reason)
              drop_pipeline_with_persistence!(failure_reason)
            else
              mark_pipeline_as_failed(failure_reason)
            end
          end

          def should_persist_pipeline_failure?(failure_reason)
            !pipeline.readonly? &&
              Enums::Ci::Pipeline.persistable_failure_reason?(failure_reason) &&
              command.save_incompleted
          end

          def drop_pipeline_with_persistence!(failure_reason)
            # Project iid must be called outside a transaction, so we ensure it is set here
            # otherwise it may be set within the state transition transaction of the drop! call
            # which it will lock the InternalId row for the whole transaction
            pipeline.ensure_project_iid!

            pipeline.drop!(failure_reason)
          end

          # This method results in no pipeline being created, but errors are recorded
          # in Ci::PipelineCreation::Requests for tracking purposes
          def mark_pipeline_as_failed(failure_reason)
            # For readonly pipelines, we only set status without tracking failures
            # For non-persistable failures or when save_incompleted is false,
            # we increment counters and set failed status
            command.increment_pipeline_failure_reason_counter(failure_reason) unless pipeline.readonly?

            pipeline.set_failed(failure_reason)
          end
        end
      end
    end
  end
end
