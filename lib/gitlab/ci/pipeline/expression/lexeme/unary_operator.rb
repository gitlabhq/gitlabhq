# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Expression
        module Lexeme
          class UnaryOperator < Lexeme::Operator
            # This operator class is designed to handle unary operators that take a single
            # operand. If we wish to implement an Operator that takes a different number of
            # arguments, a structural change or additional Operator superclass will likely be needed.

            attr_reader :operand

            def self.type
              :unary_operator
            end

            def initialize(operand)
              raise OperatorError, 'Invalid operand' unless operand.respond_to? :evaluate

              @operand = operand
            end

            def inspect
              "#{name}(#{@operand.inspect})"
            end
          end
        end
      end
    end
  end
end
