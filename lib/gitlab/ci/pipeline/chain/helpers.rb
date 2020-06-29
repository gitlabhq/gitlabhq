# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Helpers
          def error(message, config_error: false, drop_reason: nil)
            if config_error && command.save_incompleted
              drop_reason = :config_error
              pipeline.yaml_errors = message
            end

            pipeline.add_error_message(message)
            pipeline.drop!(drop_reason) if drop_reason

            # TODO: consider not to rely on AR errors directly as they can be
            # polluted with other unrelated errors (e.g. state machine)
            # https://gitlab.com/gitlab-org/gitlab/-/issues/220823
            pipeline.errors.add(:base, message)
          end
        end
      end
    end
  end
end
