module IssueLinks
  class ListService < IssuableLinks::ListService
    private

    def issues
      issuable.related_issues(current_user, preload: { project: :namespace })
    end

    def destroy_relation_path(issue)
      current_project = issuable.project

      # Make sure the user can admin both the current issue AND the
      # referenced issue projects in order to return the removal link.
      if can_destroy_issue_link_on_current_project?(current_project) && can_destroy_issue_link?(issue.project)
        project_issue_link_path(current_project, issuable.iid, issue.issue_link_id)
      end
    end

    def can_destroy_issue_link_on_current_project?(current_project)
      return @can_destroy_on_current_project if defined?(@can_destroy_on_current_project)

      @can_destroy_on_current_project = can_destroy_issue_link?(current_project)
    end

    def can_destroy_issue_link?(project)
      Ability.allowed?(current_user, :admin_issue_link, project)
    end
  end
end
