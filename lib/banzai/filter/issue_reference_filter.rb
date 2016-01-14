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

      def find_object(project, id)
        project.get_issue(id)
      end

      def url_for_object(issue, project)
        IssuesHelper.url_for_issue(issue.iid, project, only_path: context[:only_path])
      end
    end
  end
end
