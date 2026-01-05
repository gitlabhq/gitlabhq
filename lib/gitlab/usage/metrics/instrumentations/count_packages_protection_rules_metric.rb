# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountPackagesProtectionRulesMetric < DatabaseMetric
          operation :count

          relation { ::Packages::Protection::Rule }
        end
      end
    end
  end
end
