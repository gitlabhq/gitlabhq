module IssueLinks
  class ListService < IssuableLinks::ListService
    include Gitlab::Utils::StrongMemoize

    private

    def issues
      issuable.related_issues(current_user, preload: { project: :namespace })
    end

    def relation_path(issue)
      # Make sure the user can admin both the current issue AND the
      # referenced issue projects in order to return the removal link.
      if can_admin_issue_link_on_current_project? && can_admin_issue_link?(issue.project)
        project_issue_link_path(current_project, issuable.iid, issue.issue_link_id)
      end
    end

    def can_admin_issue_link_on_current_project?
      strong_memoize(:can_admin_on_current_project) do
        can_admin_issue_link?(current_project)
      end
    end

    def can_admin_issue_link?(project)
      Ability.allowed?(current_user, :admin_issue_link, project)
    end

    def current_project
      issuable.project
    end
  end
end
