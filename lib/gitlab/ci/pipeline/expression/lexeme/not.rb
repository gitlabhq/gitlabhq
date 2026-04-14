# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Expression
        module Lexeme
          class Not < Lexeme::UnaryOperator
            PATTERN = /!/

            def self.build(_value, ahead)
              new(ahead)
            end

            def self.precedence
              1 # See: https://ruby-doc.org/core-2.5.0/doc/syntax/precedence_rdoc.html
            end

            def evaluate(variables = {})
              !@operand.evaluate(variables).present?
            end
          end
        end
      end
    end
  end
end
