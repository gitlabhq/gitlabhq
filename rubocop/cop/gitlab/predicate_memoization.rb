# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      class PredicateMemoization < RuboCop::Cop::Base
        MSG = <<~EOL
          Avoid using `@value ||= query` inside predicate methods in order to
          properly memoize `false` or `nil` values.
          https://docs.gitlab.com/ee/development/utilities.html#strongmemoize
        EOL

        def on_def(node)
          return unless predicate_method?(node)

          select_offenses(node).each do |offense|
            add_offense(offense)
          end
        end

        private

        def predicate_method?(node)
          node.predicate_method?
        end

        def or_ivar_assignment?(or_assignment)
          lhs = or_assignment.each_child_node.first

          lhs.ivasgn_type?
        end

        def select_offenses(node)
          node.each_descendant(:or_asgn).select do |or_assignment|
            or_ivar_assignment?(or_assignment)
          end
        end
      end
    end
  end
end
