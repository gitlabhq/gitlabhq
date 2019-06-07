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
          end
        end
      end
    end
  end
end
