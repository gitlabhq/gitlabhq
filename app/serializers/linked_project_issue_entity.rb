# frozen_string_literal: true

class LinkedProjectIssueEntity < LinkedIssueEntity
  include Gitlab::Utils::StrongMemoize

  expose :relation_path, override: true do |issue|
    # Make sure the user can admin both the current issue AND the
    # referenced issue projects in order to return the removal link.
    if can_admin_issue_link_on_current_project? && can_admin_issue_link?(issue.project)
      project_issue_link_path(issuable.project, issuable.iid, issue.issue_link_id)
    end
  end

  expose :link_type do |issue|
    issue.issue_link_type
  end

  private

  def can_admin_issue_link_on_current_project?
    strong_memoize(:can_admin_on_current_project) do
      can_admin_issue_link?(issuable.project)
    end
  end

  def can_admin_issue_link?(project)
    Ability.allowed?(current_user, :admin_issue_link, project)
  end
end
