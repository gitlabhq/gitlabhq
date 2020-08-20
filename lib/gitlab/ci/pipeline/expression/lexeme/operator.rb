# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Expression
        module Lexeme
          class Operator < Lexeme::Base
            OperatorError = Class.new(Expression::ExpressionError)

            def self.type
              raise NotImplementedError
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
