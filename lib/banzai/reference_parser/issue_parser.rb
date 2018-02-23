module Banzai
  module ReferenceParser
    class IssueParser < IssuableParser
      self.reference_type = :issue

      def nodes_visible_to_user(user, nodes)
        issues = records_for_nodes(nodes)
        issues_to_check = issues.values

        unless can?(user, :read_cross_project)
          issues_to_check, cross_project_issues = issues_to_check.partition do |issue|
            issue.project == project
          end
        end

        readable_issues = Ability.issues_readable_by_user(issues_to_check, user).to_set

        nodes.select do |node|
          issue_in_node = issues[node]

          # We check the inclusion of readable issues first because it's faster.
          #
          # But we need to fall back to `read_issue_iid` if the user cannot read
          # cross project, since it might be possible the user can see the IID
          # but not the issue.
          if readable_issues.include?(issue_in_node)
            true
          elsif cross_project_issues&.include?(issue_in_node)
            can_read_reference?(user, issue_in_node)
          else
            false
          end
        end
      end

      def records_for_nodes(nodes)
        @issues_for_nodes ||= grouped_objects_for_nodes(
          nodes,
          Issue.all.includes(
            :author,
            :assignees,
            {
              # These associations are primarily used for checking permissions.
              # Eager loading these ensures we don't end up running dozens of
              # queries in this process.
              project: [
                { namespace: :owner },
                { group: [:owners, :group_members] },
                :invited_groups,
                :project_members,
                :project_feature
              ]
            }
          ),
          self.class.data_attribute
        )
      end
    end
  end
end
