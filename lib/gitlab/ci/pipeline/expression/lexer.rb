module Gitlab
  module Ci
    module Pipeline
      module Expression
        class Lexer
          include ::Gitlab::Utils::StrongMemoize

          LEXEMES = [
            Expression::Lexeme::Variable,
            Expression::Lexeme::String,
            Expression::Lexeme::Null,
            Expression::Lexeme::Equals
          ].freeze

          SyntaxError = Class.new(Statement::StatementError)

          MAX_TOKENS = 100

          def initialize(statement, max_tokens: MAX_TOKENS)
            @scanner = StringScanner.new(statement)
            @max_tokens = max_tokens
          end

          def tokens
            strong_memoize(:tokens) { tokenize }
          end

          def lexemes
            tokens.map(&:to_lexeme)
          end

          private

          def tokenize
            tokens = []

            @max_tokens.times do
              @scanner.skip(/\s+/) # ignore whitespace

              return tokens if @scanner.eos?

              lexeme = LEXEMES.find do |type|
                type.scan(@scanner).tap do |token|
                  tokens.push(token) if token.present?
                end
              end

              unless lexeme.present?
                raise Lexer::SyntaxError, 'Unknown lexeme found!'
              end
            end

            raise Lexer::SyntaxError, 'Too many tokens!'
          end
        end
      end
    end
  end
end
