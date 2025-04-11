# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class ClickHouseConfiguredMetric < GenericMetric
          def value
            ::Gitlab::ClickHouse.configured?
          end
        end
      end
    end
  end
end
