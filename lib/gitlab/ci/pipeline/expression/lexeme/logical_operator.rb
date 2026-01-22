# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Expression
        module Lexeme
          class LogicalOperator < Lexeme::Operator
            # This operator class is design to handle single operators that take two
            # arguments. Expression::Parser was originally designed to read infix operators,
            # and so the two operands are called "left" and "right" here. If we wish to
            # implement an Operator that takes a greater or lesser number of arguments, a
            # structural change or additional Operator superclass will likely be needed.

            attr_reader :left, :right

            def initialize(left, right)
              raise OperatorError, 'Invalid left operand' unless left.respond_to? :evaluate
              raise OperatorError, 'Invalid right operand' unless right.respond_to? :evaluate

              @left = left
              @right = right
            end

            def inspect
              "#{name}(#{@left.inspect}, #{@right.inspect})"
            end

            def self.type
              :logical_operator
            end

            private

            def compare_with_coercion(left, right)
              if boolean_string_comparison?(left, right)
                coerce_to_string(left) == coerce_to_string(right)
              else
                left == right
              end
            end

            def boolean_string_comparison?(left, right)
              (boolean?(left) && string?(right)) || (string?(left) && boolean?(right))
            end

            def boolean?(value)
              value.instance_of?(TrueClass) || value.instance_of?(FalseClass)
            end

            def string?(value)
              value.is_a?(::String)
            end

            def coerce_to_string(value)
              boolean?(value) ? value.to_s : value
            end
          end
        end
      end
    end
  end
end
