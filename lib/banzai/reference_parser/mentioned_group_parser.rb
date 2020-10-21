# frozen_string_literal: true

module Banzai
  module ReferenceParser
    class MentionedGroupParser < BaseParser
      GROUP_ATTR = 'data-group'

      self.reference_type = :user

      def self.data_attribute
        @data_attribute ||= GROUP_ATTR
      end

      def references_relation
        Group
      end

      def nodes_visible_to_user(user, nodes)
        groups = lazy { grouped_objects_for_nodes(nodes, references_relation, GROUP_ATTR) }

        nodes.select do |node|
          node.has_attribute?(GROUP_ATTR) && can_read_group_reference?(node, user, groups)
        end
      end

      def can_read_group_reference?(node, user, groups)
        node_group = groups[node]

        node_group && can?(user, :read_group, node_group)
      end
    end
  end
end
