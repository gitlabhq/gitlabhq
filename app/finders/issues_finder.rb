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
    Issue.not_restricted_by_confidentiality(current_user)
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

  def item_project_ids(items)
    items&.reorder(nil)&.select(:project_id)
  end
end
