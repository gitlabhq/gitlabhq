module Gitlab
  module Ci
    module Pipeline
      module Expression
        class Statement
          ParserError = Class.new(StandardError)

          GRAMMAR = [
            %w[variable equals string],
            %w[variable equals variable],
            %w[variable equals null],
            %w[string equals variable],
            %w[null equals variable],
            %w[variable]
          ]

          def initialize(statement, pipeline)
            @pipeline = pipeline
            @lexer = Expression::Lexer.new(statement)
          end

          def variables
          end

          def tokens
            @lexer.tokenize
          end

          def lexemes
            @lexemes ||= tokens.map(&:to_lexeme)
          end

          ##
          # Our syntax is very simple, so we don't yet need to implement a
          # recursive parser, we can use the most simple approach to create
          # a reverse descent parse tree "by hand".
          #
          def parse_tree
            raise ParserError if lexemes.empty?

            unless GRAMMAR.find { |syntax| syntax == lexemes }
              raise ParserError, 'Unknown pipeline expression!'
            end

            if tokens.many?
              Expression::Equals.new(tokens.first.build, tokens.last.build)
            else
              tokens.first.build
            end
          end

          def evaluate
            parse_tree.evaluate # evaluate(variables)
          end
        end
      end
    end
  end
end
