# frozen_string_literal: true

module Banzai
  module ReferenceParser
    class IssueParser < IssuableParser
      self.reference_type = :issue

      def nodes_visible_to_user(user, nodes)
        issues_by_node = records_for_nodes(nodes)

        readable_issues = Ability.issues_readable_by_user(issues_by_node.values, user).to_set

        nodes.select do |node|
          readable_issues.include?(issues_by_node[node])
        end
      end

      def records_for_nodes(nodes)
        @issues_for_nodes ||= grouped_objects_for_nodes(
          nodes,
          Issue.all.includes(node_includes),
          self.class.data_attribute
        )
      end

      private

      def node_includes
        includes = [
          :work_item_type,
          :namespace,
          :author,
          :assignees,
          {
            # These associations are primarily used for checking permissions.
            # Eager loading these ensures we don't end up running dozens of
            # queries in this process.
            project: [:namespace, :project_feature, :route]
          }
        ]
        includes << :milestone if context.options[:extended_preload]

        includes
      end
    end
  end
end
