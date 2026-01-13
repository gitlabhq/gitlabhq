# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountDistinctNamespacesWithPackagesProtectionRulesMetric < DatabaseMetric
          operation :distinct_count, column: 'namespaces.id'

          relation do
            ::Packages::Protection::Rule
              .joins(project: :namespace)
          end
        end
      end
    end
  end
end
