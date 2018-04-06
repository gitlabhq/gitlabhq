class Projects::GroupLinksController < Projects::ApplicationController
  layout 'project_settings'
  before_action :authorize_admin_project!
  before_action :authorize_admin_project_member!, only: [:update]
  before_action :authorize_group_share!, only: [:create]

  def index
    redirect_to namespace_project_settings_members_path
  end

  def create
    group = Group.find(params[:link_group_id]) if params[:link_group_id].present?

    if group
      return render_404 unless can?(current_user, :read_group, group)

      Projects::GroupLinks::CreateService.new(project, current_user, group_link_create_params).execute(group)
    else
      flash[:alert] = 'Please select a group.'
    end

    redirect_to project_project_members_path(project)
  end

  def update
    @group_link = @project.project_group_links.find(params[:id])

    @group_link.update_attributes(group_link_params)
  end

  def destroy
    group_link = project.project_group_links.find(params[:id])

    ::Projects::GroupLinks::DestroyService.new(project, current_user).execute(group_link)

    respond_to do |format|
      format.html do
        redirect_to project_project_members_path(project), status: 302
      end
      format.js { head :ok }
    end
  end

  protected

  def authorize_group_share!
    access_denied! unless project.allowed_to_share_with_group?
  end

  def group_link_params
    params.require(:group_link).permit(:group_access, :expires_at)
  end

  def group_link_create_params
    params.permit(:link_group_access, :expires_at)
  end
end
