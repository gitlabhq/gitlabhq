# Build collection of Merge Requests
# based on filtering passed via params for @project
class MergeRequestsLoadContext < BaseContext
  def execute
    type = params[:f]

    merge_requests = project.merge_requests

    merge_requests = case type
                     when 'all' then merge_requests
                     when 'closed' then merge_requests.closed
                     when 'assigned-to-me' then merge_requests.opened.assigned(current_user)
                     else merge_requests.opened
                     end

    merge_requests = merge_requests.page(params[:page]).per(20)
    merge_requests = merge_requests.includes(:author, :project).order("closed, created_at desc")

    # Filter by specific assignee_id (or lack thereof)?
    if params[:assignee_id].present?
      merge_requests = merge_requests.where(assignee_id: (params[:assignee_id] == '0' ? nil : params[:assignee_id]))
    end

    # Filter by specific milestone_id (or lack thereof)?
    if params[:milestone_id].present?
      merge_requests = merge_requests.where(milestone_id: (params[:milestone_id] == '0' ? nil : params[:milestone_id]))
    end

    merge_requests
  end
end
