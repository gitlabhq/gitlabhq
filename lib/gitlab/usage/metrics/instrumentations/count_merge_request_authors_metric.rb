# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountMergeRequestAuthorsMetric < DatabaseMetric
          operation :distinct_count, column: :author_id

          relation { MergeRequest }
        end
      end
    end
  end
end
