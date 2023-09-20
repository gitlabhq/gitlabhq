# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountConnectedAgentsMetric < DatabaseMetric
          operation :count

          relation do
            Clusters::AgentToken.connected
          end
        end
      end
    end
  end
end
