# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountContainerRegistryProtectionRulesMetric < DatabaseMetric
          operation :count

          relation { ::ContainerRegistry::Protection::Rule }
        end
      end
    end
  end
end
