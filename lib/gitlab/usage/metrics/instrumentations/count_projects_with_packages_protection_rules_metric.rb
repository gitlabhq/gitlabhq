# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountProjectsWithPackagesProtectionRulesMetric < DatabaseMetric
          operation :distinct_count, column: :project_id

          relation { ::Packages::Protection::Rule }
        end
      end
    end
  end
end
