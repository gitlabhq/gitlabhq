# Build collection of Merge Requests
# based on filtering passed via params for @project
class MergeRequestsLoadContext < BaseContext
  def execute
    merge_requests = @project.merge_requests

    merge_requests = case params[:state]
                     when 'all' then merge_requests
                     when 'closed' then merge_requests.closed
                     else merge_requests.opened
                     end

    merge_requests = case params[:scope]
                     when 'assigned-to-me' then merge_requests.assigned_to(current_user)
                     when 'created-by-me' then merge_requests.authored(current_user)
                     else merge_requests
                     end


    merge_requests = merge_requests.page(params[:page]).per(20)
    merge_requests = merge_requests.includes(:author, :source_project, :target_project).order("created_at desc")

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
