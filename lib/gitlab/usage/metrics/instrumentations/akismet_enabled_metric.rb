# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class AkismetEnabledMetric < GenericMetric
          value do
            Gitlab::CurrentSettings.akismet_enabled
          end
        end
      end
    end
  end
end
