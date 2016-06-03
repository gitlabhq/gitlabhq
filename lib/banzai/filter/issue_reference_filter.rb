module Banzai
  module Filter
    # HTML filter that replaces issue references with links. References to
    # issues that do not exist are ignored.
    #
    # This filter supports cross-project references.
    class IssueReferenceFilter < AbstractReferenceFilter
      def self.object_class
        Issue
      end

      def self.user_can_see_reference?(user, node, context)
        issue = Issue.find(node.attr('data-issue')) rescue nil
        Ability.abilities.allowed?(user, :read_issue, issue)
      end

      def find_object(project, id)
        project.get_issue(id)
      end

      def url_for_object(issue, project)
        IssuesHelper.url_for_issue(issue.iid, project, only_path: context[:only_path])
      end
    end
  end
end
