class TeamMembersController < ProjectResourceController
  # Authorize
  before_filter :authorize_read_project!
  before_filter :authorize_admin_project!, except: [:index, :show]

  def index
  end

  def show
    @team_member = project.users_projects.find(params[:id])
    @events = @team_member.user.recent_events.where(:project_id => @project.id).limit(7)
  end

  def new
    @team_member = project.users_projects.new
  end

  def create
    @project.add_users_ids_to_team(
      params[:user_ids],
      params[:project_access]
    )

    if params[:redirect_to]
      redirect_to params[:redirect_to]
    else
      redirect_to project_team_index_path(@project)
    end
  end

  def update
    @team_member = project.users_projects.find(params[:id])
    @team_member.update_attributes(params[:team_member])

    unless @team_member.valid?
      flash[:alert] = "User should have at least one role"
    end
    redirect_to project_team_index_path(@project)
  end

  def destroy
    @team_member = project.users_projects.find(params[:id])
    @team_member.destroy

    respond_to do |format|
      format.html { redirect_to project_team_index_path(@project) }
      format.js { render nothing: true }
    end
  end

  def apply_import
    giver = Project.find(params[:source_project_id])
    status = UsersProject.import_team(giver, project)
    notice = status ? "Succesfully imported" : "Import failed"

    redirect_to project_team_members_path(project), notice: notice
  end
end
