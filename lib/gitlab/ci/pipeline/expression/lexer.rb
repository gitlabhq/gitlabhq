module Gitlab
  module Ci
    module Pipeline
      module Expression
        class Lexer
          LEXEMES = [
            Expression::Lexeme::Variable,
            Expression::Lexeme::String,
            Expression::Lexeme::Null,
            Expression::Lexeme::Equals
          ].freeze

          MAX_CYCLES = 5
          SyntaxError = Class.new(Statement::StatementError)

          def initialize(statement)
            @scanner = StringScanner.new(statement)
            @tokens = []
          end

          def tokens
            return @tokens if @tokens.any?

            MAX_CYCLES.times do
              LEXEMES.each do |lexeme|
                @scanner.skip(/\s+/) # ignore whitespace

                lexeme.scan(@scanner).tap do |token|
                  @tokens.push(token) if token.present?
                end

                return @tokens if @scanner.eos?
              end
            end

            raise Lexer::SyntaxError unless @scanner.eos?
          end

          def lexemes
            tokens.map(&:to_lexeme)
          end
        end
      end
    end
  end
end
