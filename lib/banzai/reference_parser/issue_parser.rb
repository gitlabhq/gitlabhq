module Banzai
  module ReferenceParser
    class IssueParser < BaseParser
      self.reference_type = :issue

      def nodes_visible_to_user(user, nodes)
        # It is not possible to check access rights for external issue trackers
        return nodes if project && project.external_issue_tracker

        issues = issues_for_nodes(nodes)

        readable_issues = Ability.
          issues_readable_by_user(issues.values, user).to_set

        nodes.select do |node|
          readable_issues.include?(issue_for_node(issues, node))
        end
      end

      def referenced_by(nodes)
        issues = issues_for_nodes(nodes)

        nodes.map { |node| issue_for_node(issues, node) }.uniq
      end

      def issues_for_nodes(nodes)
        @issues_for_nodes ||= grouped_objects_for_nodes(
          nodes,
          Issue.all.includes(
            :author,
            :assignee,
            {
              # These associations are primarily used for checking permissions.
              # Eager loading these ensures we don't end up running dozens of
              # queries in this process.
              project: [
                { namespace: :owner },
                { group: [:owners, :group_members] },
                :invited_groups,
                :project_members
              ]
            }
          ),
          self.class.data_attribute
        )
      end

      private

      def issue_for_node(issues, node)
        issues[node.attr(self.class.data_attribute).to_i]
      end
    end
  end
end
