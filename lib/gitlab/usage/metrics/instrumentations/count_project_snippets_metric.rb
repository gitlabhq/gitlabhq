# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountProjectSnippetsMetric < DatabaseMetric
          operation :count

          relation do
            ProjectSnippet
          end
        end
      end
    end
  end
end
