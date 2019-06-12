# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Expression
        module Lexeme
          require_dependency 're2'

          class Pattern < Lexeme::Value
            PATTERN     = %r{^/.+/[ismU]*$}.freeze
            NEW_PATTERN = %r{^\/([^\/]|\\/)+[^\\]\/[ismU]*}.freeze

            def initialize(regexp)
              @value = self.class.eager_matching_with_escape_characters? ? regexp.gsub(/\\\//, '/') : regexp

              unless Gitlab::UntrustedRegexp::RubySyntax.valid?(@value)
                raise Lexer::SyntaxError, 'Invalid regular expression!'
              end
            end

            def evaluate(variables = {})
              Gitlab::UntrustedRegexp::RubySyntax.fabricate!(@value)
            rescue RegexpError
              raise Expression::RuntimeError, 'Invalid regular expression!'
            end

            def self.pattern
              eager_matching_with_escape_characters? ? NEW_PATTERN : PATTERN
            end

            def self.build(string)
              new(string)
            end

            def self.eager_matching_with_escape_characters?
              Feature.enabled?(:ci_variables_complex_expressions)
            end
          end
        end
      end
    end
  end
end
