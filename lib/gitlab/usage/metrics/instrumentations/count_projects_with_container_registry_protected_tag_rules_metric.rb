# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountProjectsWithContainerRegistryProtectedTagRulesMetric < DatabaseMetric
          operation :distinct_count, column: :project_id

          relation { ::ContainerRegistry::Protection::TagRule.mutable }
        end
      end
    end
  end
end
