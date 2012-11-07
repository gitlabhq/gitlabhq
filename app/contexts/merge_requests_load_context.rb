class MergeRequestsLoadContext < BaseContext
  def execute
    type = params[:f]

    merge_requests = project.merge_requests

    merge_requests = case type
                     when 'all' then merge_requests
                     when 'closed' then merge_requests.closed
                     when 'assigned-to-me' then merge_requests.opened.assigned(current_user)
                     else merge_requests.opened
                     end.page(params[:page]).per(20)

    merge_requests.includes(:author, :project).order("closed, created_at desc")
  end
end
