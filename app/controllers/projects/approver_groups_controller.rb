class Projects::ApproverGroupsController < Projects::ApplicationController
  def destroy
    if params[:merge_request_id]
      authorize_create_merge_request!
      merge_request = project.merge_requests.find_by!(iid: params[:merge_request_id])
      merge_request.approver_groups.find(params[:id]).destroy
    else
      authorize_admin_project!
      project.approver_groups.find(params[:id]).destroy
    end

    redirect_back_or_default(default: { action: 'index' })
  end
end
