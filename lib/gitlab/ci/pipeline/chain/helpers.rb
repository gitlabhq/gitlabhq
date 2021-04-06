# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Helpers
          def error(message, config_error: false, drop_reason: nil)
            if config_error
              drop_reason = :config_error
              pipeline.yaml_errors = message
            end

            pipeline.add_error_message(message)

            drop_pipeline!(drop_reason)

            # TODO: consider not to rely on AR errors directly as they can be
            # polluted with other unrelated errors (e.g. state machine)
            # https://gitlab.com/gitlab-org/gitlab/-/issues/220823
            pipeline.errors.add(:base, message)
          end

          def warning(message)
            pipeline.add_warning_message(message)
          end

          private

          def drop_pipeline!(drop_reason)
            return if pipeline.readonly?

            if drop_reason && command.save_incompleted
              pipeline.drop!(drop_reason)
            else
              command.increment_pipeline_failure_reason_counter(drop_reason)
            end
          end
        end
      end
    end
  end
end
