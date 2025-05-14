# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class SpamcheckEnabledMetric < GenericMetric
          value do
            Gitlab::CurrentSettings.spam_check_endpoint_enabled
          end
        end
      end
    end
  end
end
