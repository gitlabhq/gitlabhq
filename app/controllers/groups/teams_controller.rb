class Groups::TeamsController < Groups::ApplicationController

  before_filter :authorize_admin_group!, only: [:new, :edit, :create, :update, :destroy]

  def index
    @teams = group.user_teams
  end

  def new
    @available_teams = current_user.admin? ? UserTeam.scoped : current_user.authorized_teams
    @available_teams = group.user_teams.any? ? @available_teams.where("id not in (?)", group.user_teams) : @available_teams

    if @available_teams.blank?
      flash[:notice] = "No available teams for adding to group"
      redirect_to :back
    end
  end

  def create
    Gitlab::UserTeamManager.assign_to_group(team, group, params[:greatest_project_access])
    flash[:notice] = "Team successful added to group"
    redirect_to :back
  end

  def update
    Gitlab::UserTeamManager.update_team_user_access_in_group(team, group, params[:greatest_project_access], params[:rebuild_permissions])
    redirect_to :back
  end

  def destroy
    Gitlab::UserTeamManager.resign_from_group(team, group)
    flash[:notice] = "Team successful removed from group"
    redirect_to :back
  end

  def edit
    group
    team
  end

  protected

  def team
    @team ||= (params[:id].present? ? UserTeam.find_by_path(params[:id]) : UserTeam.find(params[:team_id]))
  end
end
