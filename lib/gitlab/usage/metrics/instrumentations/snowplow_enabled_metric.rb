# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class SnowplowEnabledMetric < GenericMetric
          def value
            Gitlab::CurrentSettings.snowplow_enabled?
          end
        end
      end
    end
  end
end
