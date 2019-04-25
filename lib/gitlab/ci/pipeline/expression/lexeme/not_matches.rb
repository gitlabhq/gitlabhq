# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Expression
        module Lexeme
          class NotMatches < Lexeme::Operator
            PATTERN = /\!~/.freeze

            def initialize(left, right)
              @left = left
              @right = right
            end

            def evaluate(variables = {})
              text = @left.evaluate(variables)
              regexp = @right.evaluate(variables)

              regexp.scan(text.to_s).none?
            end

            def self.build(_value, behind, ahead)
              new(behind, ahead)
            end
          end
        end
      end
    end
  end
end
