# frozen_string_literal: true

module Gitlab
  module Instrumentation
    module RedisInterceptor
      include RedisHelper

      def call(command)
        instrument_call([command], instrumentation_class) do
          super
        end
      end

      def call_pipeline(pipeline)
        instrument_call(pipeline.commands, instrumentation_class, true) do
          super
        end
      end

      def write(command)
        measure_write_size(command, instrumentation_class) if ::RequestStore.active?
        super
      end

      def read
        result = super
        measure_read_size(result, instrumentation_class) if ::RequestStore.active?
        result
      end

      # That's required so it knows which GitLab Redis instance
      # it's interacting with in order to categorize accordingly.
      #
      def instrumentation_class
        @options[:instrumentation_class] # rubocop:disable Gitlab/ModuleWithInstanceVariables
      end
    end
  end
end
