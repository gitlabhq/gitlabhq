# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Aggregates
        module Sources
          UnionNotAvailable = Class.new(AggregatedMetricError)
        end
      end
    end
  end
end
