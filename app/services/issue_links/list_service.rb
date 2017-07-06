module IssueLinks
  class ListService
    include Gitlab::Routing

    def initialize(issue, user)
      @issue, @current_user, @project = issue, user, issue.project
    end

    def execute
      issues.map do |referenced_issue|
        {
          id: referenced_issue.id,
          title: referenced_issue.title,
          state: referenced_issue.state,
          reference: referenced_issue.to_reference(@project),
          path: project_issue_path(referenced_issue.project, referenced_issue.iid),
          destroy_relation_path: destroy_relation_path(referenced_issue)
        }
      end
    end

    private

    def issues
      @issue.related_issues(@current_user, preload: { project: :namespace })
    end

    def destroy_relation_path(issue)
      # Make sure the user can admin both the current issue AND the
      # referenced issue projects in order to return the removal link.
      if can_destroy_issue_link_on_current_project? && can_destroy_issue_link?(issue.project)
        project_issue_link_path(@project, @issue.iid, issue.issue_link_id)
      end
    end

    def can_destroy_issue_link_on_current_project?
      return @can_destroy_on_current_project if defined?(@can_destroy_on_current_project)

      @can_destroy_on_current_project = can_destroy_issue_link?(@project)
    end

    def can_destroy_issue_link?(project)
      Ability.allowed?(@current_user, :admin_issue_link, project)
    end
  end
end
