# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class InstanceRunnerTokenExpirationEnabledMetric < GenericMetric
          def value
            !!Gitlab::CurrentSettings.runner_token_expiration_interval&.positive?
          end
        end
      end
    end
  end
end
