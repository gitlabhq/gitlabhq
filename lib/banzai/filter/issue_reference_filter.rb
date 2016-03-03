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
        project = Project.find(node.attr('data-project')) rescue nil
        return unless project

        id = node.attr('data-issue')
        issue = find_object(project, id)
        return unless issue

        if issue.is_a?(Issue) && issue.confidential?
          Ability.abilities.allowed?(user, :read_issue, issue)
        else
          super
        end
      end

      def self.find_object(project, id)
        if project.default_issues_tracker?
          project.issues.find_by(id: id)
        else
          ExternalIssue.new(id, project)
        end
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
