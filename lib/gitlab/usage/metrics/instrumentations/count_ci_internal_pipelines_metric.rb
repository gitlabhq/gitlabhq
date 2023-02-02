# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountCiInternalPipelinesMetric < DatabaseMetric
          operation :count

          relation do
            ::Ci::Pipeline.internal
          end

          def value
            return FALLBACK if Gitlab.com?

            super
          end
        end
      end
    end
  end
end
