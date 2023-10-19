# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Expression
        module Lexeme
          class Pattern < Lexeme::Value
            PATTERN = %r{^\/([^\/]|\\/)+[^\\]\/[ismU]*}

            def initialize(regexp)
              super(regexp.gsub(%r{\\/}, '/'))

              raise Lexer::SyntaxError, 'Invalid regular expression!' unless cached_regexp.valid?
            end

            def evaluate(variables = {})
              cached_regexp.expression
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

            private

            def cached_regexp
              @cached_regexp ||= RegularExpression.new(@value)
            end
          end
        end
      end
    end
  end
end
