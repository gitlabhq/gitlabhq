# frozen_string_literal: true

class LinkedProjectIssueEntity < LinkedIssueEntity
  include Gitlab::Utils::StrongMemoize

  expose :relation_path, override: true do |issue|
    # Make sure the user can admin the links of one issue and
    # create links in the other issue in order to return the removal link.
    if can_create_or_destroy_issue_link?(issue)
      project_issue_link_path(issuable.project, issuable.iid,
        issue.issue_link_id)
    end
  end

  expose :link_type do |issue|
    issue.issue_link_type
  end

  private

  # A user can create/destroy an issue link if they can
  # admin the links for one issue AND create links for the other
  def can_create_or_destroy_issue_link?(issue)
    (can_admin_issue_link?(issuable) && can_create_issue_link?(issue)) ||
      (can_admin_issue_link?(issue) && can_create_issue_link?(issuable))
  end

  def can_admin_issue_link_on_current_issue?
    strong_memoize(:can_admin_on_current_issue) do
      can_admin_issue_link?(issuable)
    end
  end

  def can_admin_issue_link?(issue)
    Ability.allowed?(current_user, :admin_issue_link, issue)
  end

  def can_create_issue_link?(issue)
    Ability.allowed?(current_user, :create_issue_link, issue)
  end
end
