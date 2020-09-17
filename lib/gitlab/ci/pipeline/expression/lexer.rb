# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Expression
        class Lexer
          include ::Gitlab::Utils::StrongMemoize

          SyntaxError = Class.new(Expression::ExpressionError)

          LEXEMES = [
            Expression::Lexeme::ParenthesisOpen,
            Expression::Lexeme::ParenthesisClose,
            Expression::Lexeme::Variable,
            Expression::Lexeme::String,
            Expression::Lexeme::Pattern,
            Expression::Lexeme::Null,
            Expression::Lexeme::Equals,
            Expression::Lexeme::Matches,
            Expression::Lexeme::NotEquals,
            Expression::Lexeme::NotMatches,
            Expression::Lexeme::And,
            Expression::Lexeme::Or
          ].freeze

          def self.lexemes
            LEXEMES
          end

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

              lexeme = self.class.lexemes.find do |type|
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
