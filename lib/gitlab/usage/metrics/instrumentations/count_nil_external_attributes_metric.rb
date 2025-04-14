# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountNilExternalAttributesMetric < DatabaseMetric
          operation :count

          relation do
            User.where(external: nil)
          end
        end
      end
    end
  end
end
