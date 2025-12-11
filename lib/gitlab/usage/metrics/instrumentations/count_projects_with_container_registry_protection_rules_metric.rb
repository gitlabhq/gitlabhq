# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountProjectsWithContainerRegistryProtectionRulesMetric < DatabaseMetric
          operation :distinct_count, column: :project_id

          relation { ::ContainerRegistry::Protection::Rule }
        end
      end
    end
  end
end
