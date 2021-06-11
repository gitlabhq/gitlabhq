# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountFooMetric < RedisHLLMetric
          def value
          end
        end
      end
    end
  end
end
