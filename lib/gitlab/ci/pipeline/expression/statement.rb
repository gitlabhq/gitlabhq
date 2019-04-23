# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Expression
        class Statement
          StatementError = Class.new(Expression::ExpressionError)

          GRAMMAR = [
            # presence matchers
            %w[variable],

            # positive matchers
            %w[variable equals string],
            %w[variable equals variable],
            %w[variable equals null],
            %w[string equals variable],
            %w[null equals variable],
            %w[variable matches pattern],

            # negative matchers
            %w[variable notequals string],
            %w[variable notequals variable],
            %w[variable notequals null],
            %w[string notequals variable],
            %w[null notequals variable],
            %w[variable notmatches pattern]
          ].freeze

          def initialize(statement, variables = {})
            @lexer = Expression::Lexer.new(statement)
            @variables = variables.with_indifferent_access
          end

          def parse_tree
            raise StatementError if @lexer.lexemes.empty?

            unless GRAMMAR.find { |syntax| syntax == @lexer.lexemes }
              raise StatementError, 'Unknown pipeline expression!'
            end

            Expression::Parser.new(@lexer.tokens).tree
          end

          def evaluate
            parse_tree.evaluate(@variables.to_h)
          end

          def truthful?
            evaluate.present?
          rescue Expression::ExpressionError
            false
          end

          def valid?
            parse_tree.is_a?(Lexeme::Base)
          rescue Expression::ExpressionError
            false
          end
        end
      end
    end
  end
end
