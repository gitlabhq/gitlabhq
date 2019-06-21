# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Expression
        class Parser
          ParseError = Class.new(Expression::ExpressionError)

          def initialize(tokens)
            @tokens = tokens.to_enum
            @nodes = []
          end

          def tree
            if Feature.enabled?(:ci_variables_complex_expressions, default_enabled: true)
              rpn_parse_tree
            else
              reverse_descent_parse_tree
            end
          end

          def self.seed(statement)
            new(Expression::Lexer.new(statement).tokens)
          end

          private

          # This produces a reverse descent parse tree.
          # It does not support precedence of operators.
          def reverse_descent_parse_tree
            while token = @tokens.next
              case token.type
              when :operator
                token.build(@nodes.pop, tree).tap do |node|
                  @nodes.push(node)
                end
              when :value
                token.build.tap do |leaf|
                  @nodes.push(leaf)
                end
              end
            end
          rescue StopIteration
            @nodes.last || Lexeme::Null.new
          end

          def rpn_parse_tree
            results = []

            tokens_rpn.each do |token|
              case token.type
              when :value
                results.push(token.build)
              when :operator
                right_operand = results.pop
                left_operand  = results.pop

                token.build(left_operand, right_operand).tap do |res|
                  results.push(res)
                end
              else
                raise ParseError, 'Unprocessable token found in parse tree'
              end
            end

            raise ParseError, 'Unreachable nodes in parse tree'  if results.count > 1
            raise ParseError, 'Empty parse tree'                 if results.count < 1

            results.pop
          end

          # Parse the expression into Reverse Polish Notation
          # (See: Shunting-yard algorithm)
          def tokens_rpn
            output = []
            operators = []

            @tokens.each do |token|
              case token.type
              when :value
                output.push(token)
              when :operator
                if operators.any? && token.lexeme.precedence >= operators.last.lexeme.precedence
                  output.push(operators.pop)
                end

                operators.push(token)
              end
            end

            output.concat(operators.reverse)
          end
        end
      end
    end
  end
end
