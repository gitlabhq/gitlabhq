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

          def initialize(statement)
            @scanner = StringScanner.new(statement)
          end

          def tokens(max: MAX_TOKENS)
            strong_memoize(:tokens) { tokenize(max) }
          end

          def lexemes
            tokens.map(&:to_lexeme)
          end

          private

          def tokenize(max_tokens)
            tokens = []

            max_tokens.times do
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
