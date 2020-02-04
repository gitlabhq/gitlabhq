# frozen_string_literal: true

# Recursive queries, with relatively low effort, can quickly spiral out of control exponentially
# and may not be picked up by depth and complexity alone.
module Gitlab
  module Graphql
    module QueryAnalyzers
      class RecursionAnalyzer
        IGNORED_FIELDS = %w(node edges nodes ofType).freeze
        RECURSION_THRESHOLD = 2

        def initial_value(query)
          {
              recurring_fields: {}
          }
        end

        def call(memo, visit_type, irep_node)
          return memo if skip_node?(irep_node)

          node_name = irep_node.ast_node.name
          times_encountered = memo[node_name] || 0

          if visit_type == :enter
            times_encountered += 1
            memo[:recurring_fields][node_name] = times_encountered if recursion_too_deep?(node_name, times_encountered)
          else
            times_encountered -= 1
          end

          memo[node_name] = times_encountered
          memo
        end

        def final_value(memo)
          recurring_fields = memo[:recurring_fields]
          recurring_fields = recurring_fields.select { |k, v| recursion_too_deep?(k, v) }
          if recurring_fields.any?
            GraphQL::AnalysisError.new("Recursive query - too many of fields '#{recurring_fields}' detected in single branch of the query")
          end
        end

        private

        def recursion_too_deep?(node_name, times_encountered)
          return if IGNORED_FIELDS.include?(node_name)

          times_encountered > recursion_threshold
        end

        def skip_node?(irep_node)
          ast_node = irep_node.ast_node
          !ast_node.is_a?(GraphQL::Language::Nodes::Field) || ast_node.selections.empty?
        end

        def recursion_threshold
          RECURSION_THRESHOLD
        end
      end
    end
  end
end
