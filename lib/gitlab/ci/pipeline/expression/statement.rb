# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Expression
        class Statement
          StatementError = Class.new(Expression::ExpressionError)

          def initialize(statement, variables = nil)
            @lexer = Expression::Lexer.new(statement)
            @variables = variables || {}
          end

          def parse_tree
            raise StatementError if @lexer.lexemes.empty?

            Expression::Parser.new(@lexer.tokens).tree
          end

          def evaluate
            parse_tree.evaluate(@variables)
          end

          def truthful?
            evaluate.present?
          rescue Expression::ExpressionError
            false
          end

          def valid?
            evaluate
            parse_tree.is_a?(Lexeme::Base)
          rescue Expression::ExpressionError
            false
          end

          def input_names
            collect_input_names(parse_tree).uniq
          rescue Expression::ExpressionError
            []
          end

          private

          def collect_input_names(node)
            return [] unless node

            if node.is_a?(Lexeme::Input)
              [node.value]
            elsif node.is_a?(Lexeme::LogicalOperator)
              collect_input_names(node.left) + collect_input_names(node.right)
            else
              []
            end
          end
        end
      end
    end
  end
end
