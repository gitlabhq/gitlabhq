# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Expression
        module Lexeme
          class ParenthesisClose < Lexeme::Operator
            PATTERN = /\)/

            def self.type
              :parenthesis_close
            end

            def self.precedence
              900
            end
          end
        end
      end
    end
  end
end
