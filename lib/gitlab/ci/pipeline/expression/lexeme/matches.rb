# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Expression
        module Lexeme
          class Matches < Lexeme::Operator
            PATTERN = /=~/.freeze

            def evaluate(variables = {})
              text = @left.evaluate(variables)
              regexp = @right.evaluate(variables)

              regexp.scan(text.to_s).any?

              if ci_variables_complex_expressions?
                # return offset of first match, or nil if no matches
                if match = regexp.scan(text.to_s).first
                  text.to_s.index(match)
                end
              else
                # return true or false
                regexp.scan(text.to_s).any?
              end
            end

            def self.build(_value, behind, ahead)
              new(behind, ahead)
            end

            def self.precedence
              10 # See: https://ruby-doc.org/core-2.5.0/doc/syntax/precedence_rdoc.html
            end

            private

            def ci_variables_complex_expressions?
              Feature.enabled?(:ci_variables_complex_expressions)
            end
          end
        end
      end
    end
  end
end
