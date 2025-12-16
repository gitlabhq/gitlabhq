# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountContainerRegistryProtectedTagRulesMetric < DatabaseMetric
          operation :count

          relation { ::ContainerRegistry::Protection::TagRule.mutable }
        end
      end
    end
  end
end
