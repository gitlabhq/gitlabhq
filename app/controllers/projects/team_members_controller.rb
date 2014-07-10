class Projects::TeamMembersController < Projects::ApplicationController
  # Authorize
  before_filter :authorize_admin_project!, except: :leave

  layout "project_settings"

  def index
    @group = @project.group
    @users_projects = @project.users_projects.order('project_access DESC')
  end

  def new
    @user_project_relation = project.users_projects.new
  end

  def create
    users = User.where(id: params[:user_ids].split(','))

    @project.team << [users, params[:project_access]]

    if params[:redirect_to]
      redirect_to params[:redirect_to]
    else
      redirect_to project_team_index_path(@project)
    end
  end

  def update
    @user_project_relation = project.users_projects.find_by(user_id: member)
    @user_project_relation.update_attributes(member_params)

    unless @user_project_relation.valid?
      flash[:alert] = "User should have at least one role"
    end
    redirect_to project_team_index_path(@project)
  end

  def destroy
    @user_project_relation = project.users_projects.find_by(user_id: member)
    @user_project_relation.destroy

    respond_to do |format|
      format.html { redirect_to project_team_index_path(@project) }
      format.js { render nothing: true }
    end
  end

  def leave
    project.users_projects.find_by(user_id: current_user).destroy

    respond_to do |format|
      format.html { redirect_to :back }
      format.js { render nothing: true }
    end
  end

  def apply_import
    giver = Project.find(params[:source_project_id])
    status = @project.team.import(giver)
    notice = status ? "Successfully imported" : "Import failed"

    redirect_to project_team_index_path(project), notice: notice
  end

  protected

  def member
    @member ||= User.find_by(username: params[:id])
  end

  def member_params
    params.require(:team_member).permit(:user_id, :project_access)
  end
end
