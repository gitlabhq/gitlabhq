class Projects::ProjectMembersController < Projects::ApplicationController
  # Authorize
  before_filter :authorize_admin_project!, except: :leave

  layout "project_settings"

  def index
    @project_members = @project.project_members

    if params[:search].present?
      users = @project.users.search(params[:search]).to_a
      @project_members = @project_members.where(user_id: users)
    end

    @project_members = @project_members.order('access_level DESC')

    @group = @project.group
    if @group
      @group_members = @group.group_members

      if params[:search].present?
        users = @group.users.search(params[:search]).to_a
        @group_members = @group_members.where(user_id: users)
      end
      
      @group_members = @group_members.order('access_level DESC').limit(20)
    end

    @project_member = @project.project_members.new
  end

  def new
    @project_member = @project.project_members.new
  end

  def create
    users = User.where(id: params[:user_ids].split(','))
    @project.team << [users, params[:access_level]]

    redirect_to namespace_project_project_members_path(@project.namespace, @project)
  end

  def update
    @project_member = @project.project_members.find_by(user_id: member)
    @project_member.update_attributes(member_params)
  end

  def destroy
    @project_member = @project.project_members.find_by(user_id: member)
    @project_member.destroy

    respond_to do |format|
      format.html do
        redirect_to namespace_project_project_members_path(@project.namespace,
                                                      @project)
      end
      format.js { render nothing: true }
    end
  end

  def leave
    @project.project_members.find_by(user_id: current_user).destroy

    respond_to do |format|
      format.html { redirect_to :back }
      format.js { render nothing: true }
    end
  end

  def apply_import
    giver = Project.find(params[:source_project_id])
    status = @project.team.import(giver)
    notice = status ? "Successfully imported" : "Import failed"

    redirect_to(namespace_project_project_members_path(project.namespace, project),
                notice: notice)
  end

  protected

  def member
    @member ||= User.find_by(username: params[:id])
  end

  def member_params
    params.require(:project_member).permit(:user_id, :access_level)
  end
end
