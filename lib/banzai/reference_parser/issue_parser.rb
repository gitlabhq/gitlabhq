module Banzai
  module ReferenceParser
    class IssueParser < Parser
      self.reference_type = :issue

      def nodes_visible_to_user(user, nodes)
        # It is not possible to check access rights for external issue trackers
        return nodes if project && project.external_issue_tracker

        issues = issues_for_nodes(nodes)
        issue_attr = 'data-issue'

        nodes.select do |node|
          issue = issues[node.attr(issue_attr).to_i]

          issue ? Ability.abilities.allowed?(user, :read_issue, issue) : false
        end
      end

      def referenced_by(nodes)
        issues_for_nodes(nodes).values
      end

      def issues_for_nodes(nodes)
        @issues_for_nodes ||= {}

        @issues_for_nodes[nodes] ||=
          grouped_objects_for_nodes(nodes, Issue, 'data-issue')
      end
    end
  end
end
