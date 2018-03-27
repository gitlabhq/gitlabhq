module Banzai
  module Filter
    # HTML filter that replaces issue references with links. References to
    # issues that do not exist are ignored.
    #
    # This filter supports cross-project references.
    #
    # When external issues tracker like Jira is activated we should not
    # use issue reference pattern, but we should still be able
    # to reference issues from other GitLab projects.
    class IssueReferenceFilter < IssuableReferenceFilter
      self.reference_type = :issue

      def self.object_class
        Issue
      end

      def url_for_object(issue, project)
        IssuesHelper.url_for_issue(issue.iid, project, only_path: context[:only_path], internal: true)
      end

      def projects_relation_for_paths(paths)
        super(paths).includes(:gitlab_issue_tracker_service)
      end

      def parent_records(parent, ids)
        parent.issues.where(iid: ids.to_a)
      end
    end
  end
end
