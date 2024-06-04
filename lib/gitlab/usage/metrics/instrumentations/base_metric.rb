# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class BaseMetric
          include Gitlab::Utils::UsageData
          include Gitlab::Usage::TimeFrame

          attr_reader :metric_definition
          attr_reader :time_frame
          attr_reader :options
          attr_reader :events

          class << self
            def available?(&block)
              return @metric_available = block if block

              return @metric_available.call if instance_variable_defined?(:@metric_available)

              true
            end

            attr_reader :metric_available
          end

          def initialize(attributes)
            @metric_definition = MetricDefinition.new(nil, attributes)
            @time_frame = attributes.fetch(:time_frame)
            @options = attributes.fetch(:options, {})
            @events = attributes.fetch(:events, {})
          end

          def instrumentation
            value
          end

          def available?
            self.class.available?
          end
        end
      end
    end
  end
end
