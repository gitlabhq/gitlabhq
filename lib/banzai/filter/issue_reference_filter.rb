module Banzai
  module Filter
    # HTML filter that replaces issue references with links. References to
    # issues that do not exist are ignored.
    #
    # This filter supports cross-project references.
    class IssueReferenceFilter < AbstractReferenceFilter
      self.reference_type = :issue

      def self.object_class
        Issue
      end

      def find_object(project, iid)
        issues_per_project[project][iid]
      end

      def url_for_object(issue, project)
        IssuesHelper.url_for_issue(issue.iid, project, only_path: context[:only_path])
      end

      def project_from_ref(ref)
        projects_per_reference[ref || current_project_path]
      end

      # Returns a Hash containing the issues per Project instance.
      def issues_per_project
        @issues_per_project ||= begin
          hash = Hash.new { |h, k| h[k] = {} }

          projects_per_reference.each do |path, project|
            issue_ids = references_per_project[path]

            if project.default_issues_tracker?
              issues = project.issues.where(iid: issue_ids.to_a)
            else
              issues = issue_ids.map { |id| ExternalIssue.new(id, project) }
            end

            issues.each do |issue|
              hash[project][issue.iid.to_i] = issue
            end
          end

          hash
        end
      end

      def find_projects_for_paths(paths)
        super(paths).includes(:gitlab_issue_tracker_service)
      end
    end
  end
end
