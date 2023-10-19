# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Expression
        module Lexeme
          class ParenthesisOpen < Lexeme::Operator
            PATTERN = /\(/

            def self.type
              :parenthesis_open
            end

            def self.precedence
              # Needs to be higher than `ParenthesisClose` and all other Lexemes
              901
            end
          end
        end
      end
    end
  end
end
