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
end
