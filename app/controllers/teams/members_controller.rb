class Teams::MembersController < Teams::ApplicationController
  # Authorize
  skip_before_filter :authorize_manage_user_team!, only: [:index]

  def index
    @members = @user_team.members
  end

  def show
    @team_member = @user_team.members.find(params[:id])
    @events = @team_member.recent_events.limit(7)
  end

  def new
    @team_member = @user_team.members.new
  end

  def create
    users = User.where(id: params[:user_ids])

    @project.team << [users, params[:default_project_access]]

    if params[:redirect_to]
      redirect_to params[:redirect_to]
    else
      redirect_to project_team_index_path(@project)
    end
  end

  def update
    @team_member = @user_team.members.find(params[:id])
    @team_member.update_attributes(params[:team_member])

    unless @team_member.valid?
      flash[:alert] = "User should have at least one role"
    end
    redirect_to team_member_path(@project)
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
    status = @project.team.import(giver)
    notice = status ? "Succesfully imported" : "Import failed"

    redirect_to project_team_members_path(project), notice: notice
  end

end
