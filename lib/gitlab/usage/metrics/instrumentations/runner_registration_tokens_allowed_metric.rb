# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class RunnerRegistrationTokensAllowedMetric < GenericMetric
          def value
            Gitlab::CurrentSettings.allow_runner_registration_token?
          end
        end
      end
    end
  end
end
