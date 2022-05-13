# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Expression
        module Lexeme
          require_dependency 're2'

          class Pattern < Lexeme::Value
            PATTERN = %r{^\/([^\/]|\\/)+[^\\]\/[ismU]*}.freeze

            def initialize(regexp)
              super(regexp.gsub(%r{\\/}, '/'))

              unless Gitlab::UntrustedRegexp::RubySyntax.valid?(@value)
                raise Lexer::SyntaxError, 'Invalid regular expression!'
              end
            end

            def evaluate(variables = {})
              Gitlab::UntrustedRegexp::RubySyntax.fabricate!(@value)
            rescue RegexpError
              raise Expression::RuntimeError, 'Invalid regular expression!'
            end

            def inspect
              "/#{value}/"
            end

            def self.pattern
              PATTERN
            end

            def self.build(string)
              new(string)
            end

            def self.build_and_evaluate(data, variables = {})
              return data if data.is_a?(Gitlab::UntrustedRegexp)

              begin
                new_pattern = build(data)
              rescue Lexer::SyntaxError
                return data
              end

              new_pattern.evaluate(variables)
            end
          end
        end
      end
    end
  end
end
