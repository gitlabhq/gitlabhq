# Finders::Issues class
#
# Used to filter Issues collections by set of params
#
# Arguments:
#   current_user - which user use
#   params:
#     scope: 'created-by-me' or 'assigned-to-me' or 'all'
#     state: 'open' or 'closed' or 'all'
#     group_id: integer
#     project_id: integer
#     milestone_id: integer
#     assignee_id: integer
#     search: string
#     label_name: string
#     sort: string
#
class IssuesFinder < IssuableFinder
  def klass
    Issue
  end

  private

  def init_collection
    IssuesFinder.not_restricted_by_confidentiality(current_user)
  end

  def by_assignee(items)
    if assignee
      items = items.where("issue_assignees.user_id = ?", assignee.id)
    elsif no_assignee?
      items = items.where("issue_assignees.user_id is NULL")
    elsif assignee_id? || assignee_username? # assignee not found
      items = items.none
    end

    items
  end

  def by_scope(items)
    case params[:scope]
    when 'created-by-me', 'authored'
      items.where(author_id: current_user.id)
    when 'assigned-to-me'
      items.where("issue_assignees.user_id = ?", current_user.id)
    else
      items
    end
  end

  def self.not_restricted_by_confidentiality(user)
    issues = Issue.with_assignees

    return issues.where('issues.confidential IS NULL OR issues.confidential IS FALSE') if user.blank?

    return issues.all if user.admin_or_auditor?

    issues.where('
      issues.confidential IS NULL
      OR issues.confidential IS FALSE
      OR (issues.confidential = TRUE
        AND (issues.author_id = :user_id
          OR issue_assignees.user_id = :user_id
          OR issues.project_id IN(:project_ids)))',
      user_id: user.id,
      project_ids: user.authorized_projects(Gitlab::Access::REPORTER).select(:id))
  end

  def item_project_ids(items)
    items&.reorder(nil)&.select(:project_id)
  end
end
