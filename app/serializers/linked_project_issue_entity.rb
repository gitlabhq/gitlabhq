# frozen_string_literal: true

class LinkedProjectIssueEntity < LinkedIssueEntity
  include Gitlab::Utils::StrongMemoize

  expose :relation_path, override: true do |issue|
    # Make sure the user can admin the links on both issues
    # in order to return the removal link.
    if can_admin_issue_link?(issuable) && can_admin_issue_link?(issue)
      project_issue_link_path(issuable.project, issuable.iid,
        issue.issue_link_id)
    end
  end

  expose :link_type do |issue|
    issue.issue_link_type
  end

  private

  def can_admin_issue_link?(issue)
    Ability.allowed?(current_user, :admin_issue_link, issue)
  end
end
