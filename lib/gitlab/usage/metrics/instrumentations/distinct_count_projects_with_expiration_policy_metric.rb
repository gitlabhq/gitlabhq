# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class DistinctCountProjectsWithExpirationPolicyMetric < DatabaseMetric
          operation :distinct_count, column: :project_id

          start { Project.minimum(:id) }
          finish { Project.maximum(:id) }

          cache_start_and_finish_as :project_id

          relation ->(options) do
            options.each_with_object(::ContainerExpirationPolicy.all) do |(key, value), ar_relation|
              ar_relation.where!(key => value)
            end
          end
        end
      end
    end
  end
end
