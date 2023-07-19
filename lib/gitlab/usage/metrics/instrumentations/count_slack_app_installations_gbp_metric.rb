# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountSlackAppInstallationsGbpMetric < DatabaseMetric
          operation :count

          relation { SlackIntegration.with_bot }
        end
      end
    end
  end
end
