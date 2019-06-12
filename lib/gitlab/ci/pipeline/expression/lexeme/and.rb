# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Expression
        module Lexeme
          class And < Lexeme::Operator
            PATTERN = /&&/.freeze

            def evaluate(variables = {})
              @left.evaluate(variables) && @right.evaluate(variables)
            end

            def self.build(_value, behind, ahead)
              new(behind, ahead)
            end

            def self.precedence
              11 # See: https://ruby-doc.org/core-2.5.0/doc/syntax/precedence_rdoc.html
            end
          end
        end
      end
    end
  end
end
