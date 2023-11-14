# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class ProjectImportsCreatorsMetric < DatabaseMetric
          operation :distinct_count, column: :creator_id

          relation do
            ::Project.where.not(import_type: nil)
          end
        end
      end
    end
  end
end
