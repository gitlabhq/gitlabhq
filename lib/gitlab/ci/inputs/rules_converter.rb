# frozen_string_literal: true

module Gitlab
  module Ci
    module Inputs
      ##
      #
      # Converts parsed expression AST nodes JSON format with operator, field, value, and children.
      #
      class RulesConverter
        def convert(node)
          return unless node

          case node
          when Gitlab::Ci::Pipeline::Expression::Lexeme::Equals
            {
              'operator' => 'equals',
              'field' => extract_input_name(node.left),
              'value' => extract_value(node.right)
            }
          when Gitlab::Ci::Pipeline::Expression::Lexeme::NotEquals
            {
              'operator' => 'not_equals',
              'field' => extract_input_name(node.left),
              'value' => extract_value(node.right)
            }
          when Gitlab::Ci::Pipeline::Expression::Lexeme::And
            {
              'operator' => 'AND',
              'children' => [convert(node.left), convert(node.right)].compact
            }
          when Gitlab::Ci::Pipeline::Expression::Lexeme::Or
            {
              'operator' => 'OR',
              'children' => [convert(node.left), convert(node.right)].compact
            }
          end
        end

        private

        def extract_input_name(node)
          return unless node.is_a?(Gitlab::Ci::Pipeline::Expression::Lexeme::Input)

          node.value
        end

        def extract_value(node)
          return unless node.is_a?(Gitlab::Ci::Pipeline::Expression::Lexeme::String)

          node.evaluate
        end
      end
    end
  end
end
