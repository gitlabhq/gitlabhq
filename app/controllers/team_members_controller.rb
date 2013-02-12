class TeamMembersController < ProjectResourceController
  # Authorize
  before_filter :authorize_read_project!
  before_filter :authorize_admin_project!, except: [:index, :show]

  def index
    @teams = UserTeam.scoped
  end

  def show
    @user_project_relation = project.users_projects.find_by_user_id(member)
    @events = member.recent_events.in_projects(project).limit(7)
  end

  def new
    @user_project_relation = project.users_projects.new
  end

  def create
    users = User.where(id: params[:user_ids])

    @project.team << [users, params[:project_access]]

    if params[:redirect_to]
      redirect_to params[:redirect_to]
    else
      redirect_to project_team_index_path(@project)
    end
  end

  def update
    @user_project_relation = project.users_projects.find_by_user_id(member)
    @user_project_relation.update_attributes(params[:team_member])

    unless @user_project_relation.valid?
      flash[:alert] = "User should have at least one role"
    end
    redirect_to project_team_index_path(@project)
  end

  def destroy
    @user_project_relation = project.users_projects.find_by_user_id(member)
    @user_project_relation.destroy

    respond_to do |format|
      format.html { redirect_to project_team_index_path(@project) }
      format.js { render nothing: true }
    end
  end

  def apply_import
    giver = Project.find(params[:source_project_id])
    status = @project.team.import(giver)
    notice = status ? "Succesfully imported" : "Import failed"

    redirect_to project_team_members_path(project), notice: notice
  end

  protected

  def member
    @member ||= User.find_by_username(params[:id])
  end
end
