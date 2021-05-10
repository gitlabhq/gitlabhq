# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountUsersCreatingIssuesMetric < DatabaseMetric
          operation :distinct_count, column: :author_id

          relation { Issue }
        end
      end
    end
  end
end
