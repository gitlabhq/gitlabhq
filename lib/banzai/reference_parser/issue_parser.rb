module Banzai
  module ReferenceParser
    class IssueParser < BaseParser
      self.reference_type = :issue

      def nodes_visible_to_user(user, nodes)
        # It is not possible to check access rights for external issue trackers
        return nodes if project && project.external_issue_tracker

        issues_for_nodes_visible_to_user(user, nodes).values
      end

      def issues_for_nodes_visible_to_user(user, nodes)
        nodes2issues = issues_for_nodes(nodes)

        readable_issues = Ability.
          issues_readable_by_user(nodes2issues.values, user).to_set

        nodes2issues.each_with_object({}) do |(node, issue), result|
          result[node] = issue if readable_issues.include?(issue)
        end
      end

      def referenced_by(nodes)
        issues = issues_for_nodes(nodes)

        nodes.map { |node| issues[node] }.compact.uniq
      end

      # FIXME: We should not memorize values which could ignore arguments!
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
    end
  end
end
