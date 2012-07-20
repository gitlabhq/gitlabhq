class MergeRequestsLoad < BaseContext
  def execute
    type = params[:f].to_i

    merge_requests = project.merge_requests

    merge_requests = case type
                     when 1 then merge_requests
                     when 2 then merge_requests.closed
                     when 3 then merge_requests.opened.assigned(current_user)
                     else merge_requests.opened
                     end.page(params[:page]).per(20)

    merge_requests.includes(:author, :project).order("closed, created_at desc")
  end
end
