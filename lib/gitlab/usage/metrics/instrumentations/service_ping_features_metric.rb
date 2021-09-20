# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class ServicePingFeaturesMetric < GenericMetric
          value do
            Gitlab::CurrentSettings.usage_ping_features_enabled
          end
        end
      end
    end
  end
end
