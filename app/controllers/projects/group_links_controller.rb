class Projects::GroupLinksController < Projects::ApplicationController
  layout 'project_settings'
  before_action :authorize_admin_project!
  before_action :authorize_admin_project_member!, only: [:update]

  def index
    redirect_to namespace_project_settings_members_path
  end

  def create
    group = Group.find(params[:link_group_id]) if params[:link_group_id].present?

    if group
      return render_404 unless can?(current_user, :read_group, group)

      project.project_group_links.create(
        group: group,
        group_access: params[:link_group_access],
        expires_at: params[:expires_at]
      )
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
    project.project_group_links.find(params[:id]).destroy

    respond_to do |format|
      format.html do
        redirect_to project_project_members_path(project), status: 302
      end
      format.js { head :ok }
    end
  end

  protected

  def group_link_params
    params.require(:group_link).permit(:group_access, :expires_at)
  end
end
