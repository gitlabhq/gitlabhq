# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountFooMetric < NumbersMetric
          operation :add

          data do |time_frame|
            [
              # Insert numbers here
            ]
          end
        end
      end
    end
  end
end
