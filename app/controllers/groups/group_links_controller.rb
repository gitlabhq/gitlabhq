class Groups::GroupLinksController < Groups::ApplicationController
  # before_action :authorize_admin_project!
  # before_action :authorize_admin_project_member!, only: [:update]
  before_action :group

  def create
    shared_group = Group.find(params[:shared_group_id]) if params[:shared_group_id].present?

    Groups::GroupLinks::CreateService.new(group, current_user, group_link_create_params).execute(shared_group)

    redirect_to group_group_members_path(group)
  end

  protected

  def group_link_create_params
    params.permit(:shared_group_access, :expires_at)
  end
end
