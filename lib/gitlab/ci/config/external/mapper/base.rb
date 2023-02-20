# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        class Mapper
          # Base class for mapper classes
          class Base
            def initialize(context)
              @context = context
            end

            def process(...)
              context.logger.instrument(mapper_instrumentation_key) do
                process_without_instrumentation(...)
              end
            end

            private

            attr_reader :context

            def process_without_instrumentation
              raise NotImplementedError
            end

            def mapper_instrumentation_key
              "config_mapper_#{self.class.name.demodulize.downcase}".to_sym
            end
          end
        end
      end
    end
  end
end
