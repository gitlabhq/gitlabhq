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
#     milestone_title: string
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
      items.assigned_to(assignee)
    elsif no_assignee?
      items.unassigned
    elsif assignee_id? || assignee_username? # assignee not found
      items.none
    else
      items
    end
  end

  def self.not_restricted_by_confidentiality(user)
    return Issue.where('issues.confidential IS NOT TRUE') if user.blank?

    return Issue.all if user.admin?

    Issue.where('
      issues.confidential IS NOT TRUE
      OR (issues.confidential = TRUE
        AND (issues.author_id = :user_id
          OR EXISTS (SELECT TRUE FROM issue_assignees WHERE user_id = :user_id AND issue_id = issues.id)
          OR issues.project_id IN(:project_ids)))',
      user_id: user.id,
      project_ids: user.authorized_projects(Gitlab::Access::REPORTER).select(:id))
  end

  def item_project_ids(items)
    items&.reorder(nil)&.select(:project_id)
  end
end
