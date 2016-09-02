class Projects::GroupLinksController < Projects::ApplicationController
  layout 'project_settings'
  before_action :authorize_admin_project!

  def index
    @group_links = project.project_group_links.all
  end

  def create
    group = Group.find(params[:link_group_id])
    return render_404 unless can?(current_user, :read_group, group)

    project.project_group_links.create(
      group: group,
      group_access: params[:link_group_access],
      expires_at: params[:expires_at]
    )

    redirect_to namespace_project_group_links_path(project.namespace, project)
  end

  def update
    @group_link = @project.project_group_links.find(params[:id])
    return render_403 unless can?(current_user, :admin_group, @group_link.group)

    @group_link.update_attributes(group_link_params)
  end

  def destroy
    project.project_group_links.find(params[:id]).destroy

    redirect_to namespace_project_group_links_path(project.namespace, project)
  end

  protected

  def group_link_params
    params.require(:group_link).permit(:group_access, :expires_at)
  end
end
