module Gitlab
  module Ci
    module Pipeline
      module Expression
        LEXEMES = [
          Expression::Variable
        ]

        MAX_CYCLES = 5

        class Lexer
          def initialize(statement)
            @scanner = StringScanner.new(statement)
            @tokens = []
          end

          def tokenize
            @tokens.tap do
              MAX_CYCLES.times do
                LEXEMES.each do |lexeme|
                  @scanner.scan(/\s+/) # ignore whitespace

                  lexeme.scan(@scanner).tap do |token|
                    @tokens.push(token) if token.present?
                  end

                  return @tokens if @scanner.eos?
                end
              end
            end
          end
        end
      end
    end
  end
end
