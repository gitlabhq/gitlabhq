# frozen_string_literal: true

module Gitlab
  module Ci
    module Inputs
      ##
      # Converts parsed expression AST nodes to JSON format with operator, field, value, and children.
      #
      class RulesConverter
        def convert(node)
          return unless node

          case node
          when Gitlab::Ci::Pipeline::Expression::Lexeme::Equals
            comparison_node('equals', node)
          when Gitlab::Ci::Pipeline::Expression::Lexeme::NotEquals
            comparison_node('not_equals', node)
          when Gitlab::Ci::Pipeline::Expression::Lexeme::And
            logical_node('AND', node, Gitlab::Ci::Pipeline::Expression::Lexeme::And)
          when Gitlab::Ci::Pipeline::Expression::Lexeme::Or
            logical_node('OR', node, Gitlab::Ci::Pipeline::Expression::Lexeme::Or)
          end
        end

        private

        def comparison_node(operator, node)
          {
            'operator' => operator,
            'field' => extract_input_name(node.left),
            'value' => extract_value(node.right)
          }
        end

        def logical_node(operator, node, operator_class)
          {
            'operator' => operator,
            'children' => flatten_children(node, operator_class)
          }
        end

        def flatten_children(node, operator_class)
          children = []
          collect_children(node, operator_class, children)
          children.compact
        end

        def collect_children(node, operator_class, children)
          if node.is_a?(operator_class)
            collect_children(node.left, operator_class, children)
            collect_children(node.right, operator_class, children)
          else
            children << convert(node)
          end
        end

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
