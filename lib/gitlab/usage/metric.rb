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
        with_availability(proc { instrumentation_object.value })
      end

      def with_instrumentation
        with_availability(proc { instrumentation_object.instrumentation })
      end

      private

      def with_availability(value_proc)
        return {} unless instrumentation_object.available?

        unflatten_key_path(value_proc.call)
      end

      def unflatten_key_path(value)
        ::Gitlab::Usage::Metrics::KeyPathProcessor.process(definition.key_path, value)
      end

      def instrumentation_object
        instrumentation_class = "Gitlab::Usage::Metrics::Instrumentations::#{definition.instrumentation_class}"
        @instrumentation_object ||= instrumentation_class.constantize.new(definition.raw_attributes)
      end
    end
  end
end
