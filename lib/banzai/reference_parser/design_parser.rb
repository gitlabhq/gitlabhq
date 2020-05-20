# frozen_string_literal: true

module Banzai
  module ReferenceParser
    class DesignParser < BaseParser
      self.reference_type = :design

      def references_relation
        DesignManagement::Design
      end

      def nodes_visible_to_user(user, nodes)
        issues = issues_for_nodes(nodes)
        issue_attr = 'data-issue'

        nodes.select do |node|
          if node.has_attribute?(issue_attr)
            can?(user, :read_design, issues[node])
          else
            true
          end
        end
      end

      def issues_for_nodes(nodes)
        relation = Issue.includes(project: [:project_feature])
        grouped_objects_for_nodes(nodes, relation, 'data-issue')
      end
    end
  end
end
