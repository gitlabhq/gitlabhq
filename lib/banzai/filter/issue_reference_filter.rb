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
    class IssueReferenceFilter < AbstractReferenceFilter
      self.reference_type = :issue

      def self.object_class
        Issue
      end

      # Don't use the reference pattern if the default tracker is disabled,
      # unless this is a cross-project reference.
      def uses_reference_pattern?(cross_reference_project = nil)
        cross_reference_project || context[:project].default_issues_tracker?
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

      def object_link_title(object)
        if object.is_a?(ExternalIssue)
          "Issue in #{object.project.external_issue_tracker.title}"
        else
          super
        end
      end

      def data_attributes_for(text, project, object)
        if object.is_a?(ExternalIssue)
          data_attribute(
            project: project.id,
            external_issue: object.id,
            reference_type: ExternalIssueReferenceFilter.reference_type
          )
        else
          super
        end
      end

      def projects_relation_for_paths(paths)
        super(paths).includes(:gitlab_issue_tracker_service)
      end
    end
  end
end
