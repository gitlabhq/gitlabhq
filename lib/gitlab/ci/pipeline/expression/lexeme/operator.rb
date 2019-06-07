# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Expression
        module Lexeme
          class Operator < Lexeme::Base
            # This operator class is design to handle single operators that take two
            # arguments. Expression::Parser was originally designed to read infix operators,
            # and so the two operands are called "left" and "right" here. If we wish to
            # implement an Operator that takes a greater or lesser number of arguments, a
            # structural change or additional Operator superclass will likely be needed.

            OperatorError = Class.new(Expression::ExpressionError)

            def initialize(left, right)
              raise OperatorError, 'Invalid left operand' unless left.respond_to? :evaluate
              raise OperatorError, 'Invalid right operand' unless right.respond_to? :evaluate

              @left = left
              @right = right
            end

            def self.type
              :operator
            end

            def self.precedence
              raise NotImplementedError
            end
          end
        end
      end
    end
  end
end
