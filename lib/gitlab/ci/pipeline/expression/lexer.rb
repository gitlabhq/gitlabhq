module Gitlab
  module Ci
    module Pipeline
      module Expression
        class Lexer
          LEXEMES = [
            Expression::Variable,
            Expression::String,
            Expression::Equals
          ].freeze

          MAX_CYCLES = 5
          SyntaxError = Class.new(StandardError)

          def initialize(statement)
            @scanner = StringScanner.new(statement)
            @tokens = []
          end

          def tokenize
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
        end
      end
    end
  end
end
