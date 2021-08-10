# frozen_string_literal: true

module Gitlab
  module Usage
    class Metric
      attr_reader :definition

      def initialize(definition)
        @definition = definition
      end

      class << self
        def all
          @all ||= Gitlab::Usage::MetricDefinition.with_instrumentation_class.map do |definition|
            self.new(definition)
          end
        end
      end

      def with_value
        unflatten_key_path(intrumentation_object.value)
      end

      def with_instrumentation
        unflatten_key_path(intrumentation_object.instrumentation)
      end

      private

      def unflatten_key_path(value)
        ::Gitlab::Usage::Metrics::KeyPathProcessor.process(definition.key_path, value)
      end

      def instrumentation_class
        "Gitlab::Usage::Metrics::Instrumentations::#{definition.instrumentation_class}"
      end

      def intrumentation_object
        instrumentation_class.constantize.new(
          time_frame: definition.time_frame,
          options: definition.attributes[:options]
        )
      end
    end
  end
end
