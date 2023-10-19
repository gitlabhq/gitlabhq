# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Interpolation
        module Functions
          class Base
            attr_reader :errors

            def self.function_expression_pattern
              raise NotImplementedError
            end

            def self.name
              raise NotImplementedError
            end

            def self.matches?(function_expression)
              function_expression_pattern.match?(function_expression)
            end

            def initialize(function_expression, ctx)
              @errors = []
              @function_args = parse_args(function_expression)
              @ctx = ctx
            end

            def valid?
              errors.empty?
            end

            def execute(_input_value)
              raise NotImplementedError
            end

            private

            attr_reader :function_args, :ctx

            def error(message)
              errors << "error in `#{self.class.name}` function: #{message}"
              nil
            end

            def parse_args(function_expression)
              self.class.function_expression_pattern.match(function_expression)
            end
          end
        end
      end
    end
  end
end
