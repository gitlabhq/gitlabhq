# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Interpolation
        ##
        # This class matches the given function string with a predefined
        # function and then applies it to the input value.
        #
        class FunctionsStack
          Output = Struct.new(:value, :errors) do
            def success?
              errors.empty?
            end
          end

          FUNCTIONS = [
            Functions::Truncate,
            Functions::ExpandVars,
            Functions::PosixEscape,
            Functions::Split
          ].freeze

          attr_reader :errors

          def initialize(function_expressions, ctx)
            @ctx = ctx
            @errors = []
            @functions = build_stack(function_expressions)
          end

          def valid?
            errors.none?
          end

          def evaluate(input_value)
            return Output.new(nil, errors) unless valid?

            functions.reduce(Output.new(input_value, [])) do |output, function|
              break output unless output.success?

              output_value = function.execute(output.value)

              if function.valid?
                Output.new(output_value, [])
              else
                Output.new(nil, function.errors)
              end
            end
          end

          private

          attr_reader :functions, :ctx

          def build_stack(function_expressions)
            function_expressions.each_with_index.filter_map do |function_expression, index|
              matching_function = FUNCTIONS.find { |function| function.matches?(function_expression) }

              if matching_function.present?
                if matching_function == Functions::Split && index < function_expressions.length - 1
                  errors << "split() must be the last function in a chain (it returns an array, not a string)"
                  next
                end

                matching_function.new(function_expression, ctx)
              else
                message = "no function matching `#{function_expression}`: " \
                          'check that the function name, arguments, and types are correct'

                errors << message
              end
            end
          end
        end
      end
    end
  end
end
