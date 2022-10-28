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

          relation ->(options) { ::ContainerExpirationPolicy.where(enabled: options[:enabled]) }
        end
      end
    end
  end
end
