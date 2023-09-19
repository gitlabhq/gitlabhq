# frozen_string_literal: true

# Recursive queries, with relatively low effort, can quickly spiral out of control exponentially
# and may not be picked up by depth and complexity alone.
module Gitlab
  module Graphql
    module QueryAnalyzers
      module AST
        class RecursionAnalyzer < GraphQL::Analysis::AST::Analyzer
          IGNORED_FIELDS = %w[node edges nodes ofType].freeze
          RECURSION_THRESHOLD = 2

          def initialize(query)
            super

            @node_visits = {}
            @recurring_fields = {}
          end

          def on_enter_field(node, _parent, visitor)
            return if skip_node?(node, visitor)

            node_name = node.name
            node_visits[node_name] ||= 0
            node_visits[node_name] += 1

            times_encountered = @node_visits[node_name]
            recurring_fields[node_name] = times_encountered if recursion_too_deep?(node_name, times_encountered)
          end

          # Visitors are all defined on the AST::Analyzer base class
          # We override them for custom analyzers.
          def on_leave_field(node, _parent, visitor)
            return if skip_node?(node, visitor)

            node_name = node.name
            node_visits[node_name] ||= 0
            node_visits[node_name] -= 1
          end

          def result
            @recurring_fields = @recurring_fields.select { |k, v| recursion_too_deep?(k, v) }

            if @recurring_fields.any?
              GraphQL::AnalysisError.new(<<~MSG)
                Recursive query - too many of fields '#{@recurring_fields}' detected
                in single branch of the query")
              MSG
            end
          end

          private

          attr_reader :node_visits, :recurring_fields

          def recursion_too_deep?(node_name, times_encountered)
            return if IGNORED_FIELDS.include?(node_name)

            times_encountered > recursion_threshold
          end

          def skip_node?(node, visitor)
            # We don't want to count skipped fields or fields
            # inside fragment definitions
            return false if visitor.skipping? || visitor.visiting_fragment_definition?

            !node.is_a?(GraphQL::Language::Nodes::Field) || node.selections.empty?
          end

          # separated into a method for use in allow_high_graphql_recursion
          def recursion_threshold
            RECURSION_THRESHOLD
          end
        end
      end
    end
  end
end
