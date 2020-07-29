# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Expression
        module Lexeme
          class Base
            def evaluate(**variables)
              raise NotImplementedError
            end

            def name
              self.class.name.demodulize.underscore
            end

            def self.build(token)
              raise NotImplementedError
            end

            def self.scan(scanner)
              if scanner.scan(pattern)
                Expression::Token.new(scanner.matched, self)
              end
            end

            def self.pattern
              self::PATTERN
            end

            def self.consume?(lexeme)
              lexeme && precedence >= lexeme.precedence
            end
          end
        end
      end
    end
  end
end
