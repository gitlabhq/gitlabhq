# Finders::MergeRequest class
#
# Used to filter MergeRequests collections by set of params
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
#     non_archived: boolean
#
class MergeRequestsFinder < IssuableFinder
  def klass
    MergeRequest
  end

  private

  def item_project_ids(items)
    items&.reorder(nil)&.select(:target_project_id)
  end
end
