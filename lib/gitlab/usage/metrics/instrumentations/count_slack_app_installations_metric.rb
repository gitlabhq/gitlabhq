# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountSlackAppInstallationsMetric < DatabaseMetric
          operation :count

          relation { SlackIntegration }
        end
      end
    end
  end
end
