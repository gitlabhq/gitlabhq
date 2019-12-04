# frozen_string_literal: true

module RuboCop
  module Cop
    # Checks for a group routes outside '/-/' scope.
    # For more information see: https://gitlab.com/gitlab-org/gitlab/issues/29572
    class PutGroupRoutesUnderScope < RuboCop::Cop::Cop
      MSG = 'Put new group routes under /-/ scope'

      def_node_matcher :dash_scope?, <<~PATTERN
        (:send nil? :scope (hash <(pair (sym :path)(str "groups/*group_id/-")) ...>))
      PATTERN

      def on_send(node)
        return unless in_group_routes?(node)
        return unless resource?(node)
        return unless outside_scope?(node)

        add_offense(node)
      end

      def outside_scope?(node)
        node.each_ancestor(:block).none? do |parent|
          dash_scope?(parent.to_a.first)
        end
      end

      def in_group_routes?(node)
        path = node.location.expression.source_buffer.name
        dirname = File.dirname(path)
        filename = File.basename(path)

        dirname.end_with?('config/routes') &&
          filename.end_with?('group.rb')
      end

      def resource?(node)
        node.method_name == :resource ||
          node.method_name == :resources
      end
    end
  end
end
