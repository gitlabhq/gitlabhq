# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Helpers
          def error(message, config_error: false, drop_reason: nil)
            sanitized_message = ActionController::Base.helpers.sanitize(message, tags: [])

            if config_error
              drop_reason = :config_error
              pipeline.yaml_errors = sanitized_message
            end

            pipeline.add_error_message(sanitized_message)

            drop_pipeline!(drop_reason)

            # TODO: consider not to rely on AR errors directly as they can be
            # polluted with other unrelated errors (e.g. state machine)
            # https://gitlab.com/gitlab-org/gitlab/-/issues/220823
            pipeline.errors.add(:base, sanitized_message)

            pipeline.errors.full_messages
          end

          def warning(message)
            sanitized_message = ActionController::Base.helpers.sanitize(message, tags: [])
            pipeline.add_warning_message(sanitized_message)
          end

          private

          def drop_pipeline!(drop_reason)
            return if pipeline.readonly?

            if Enums::Ci::Pipeline.persistable_failure_reason?(drop_reason) && command.save_incompleted
              # Project iid must be called outside a transaction, so we ensure it is set here
              # otherwise it may be set within the state transition transaction of the drop! call
              # which it will lock the InternalId row for the whole transaction
              pipeline.ensure_project_iid!

              pipeline.drop!(drop_reason)
            else
              command.increment_pipeline_failure_reason_counter(drop_reason)

              pipeline.set_failed(drop_reason)
            end
          end
        end
      end
    end
  end
end
