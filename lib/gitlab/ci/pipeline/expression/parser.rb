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
            results = []

            tokens = tokens_rpn

            tokens.each do |token|
              case token.type
              when :value
                results.push(token.build)
              when :logical_operator
                right_operand = results.pop
                left_operand  = results.pop

                token.build(left_operand, right_operand).tap do |res|
                  results.push(res)
                end
              else
                raise ParseError, "Unprocessable token found in parse tree: #{token.type}"
              end
            end

            raise ParseError, 'Unreachable nodes in parse tree'  if results.count > 1
            raise ParseError, 'Empty parse tree'                 if results.count < 1

            results.pop
          end

          def self.seed(statement)
            new(Expression::Lexer.new(statement).tokens)
          end

          private

          # Parse the expression into Reverse Polish Notation
          # (See: Shunting-yard algorithm)
          # Taken from: https://en.wikipedia.org/wiki/Shunting-yard_algorithm#The_algorithm_in_detail
          def tokens_rpn
            output = []
            operators = []

            @tokens.each do |token|
              case token.type
              when :value
                output.push(token)
              when :logical_operator
                output.push(operators.pop) while token.lexeme.consume?(operators.last&.lexeme)

                operators.push(token)
              when :parenthesis_open
                operators.push(token)
              when :parenthesis_close
                output.push(operators.pop) while token.lexeme.consume?(operators.last&.lexeme)

                raise ParseError, 'Unmatched parenthesis' unless operators.last

                operators.pop if operators.last.lexeme.type == :parenthesis_open
              end
            end

            output.concat(operators.reverse)
          end
        end
      end
    end
  end
end
