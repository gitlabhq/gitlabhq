class Projects::TeamsController < Projects::ApplicationController

  before_filter :authorize_admin_team_member!

  def available
    @teams = current_user.is_admin? ? UserTeam.scoped : current_user.user_teams
    @teams = @teams.without_project(project)
    unless @teams.any?
      redirect_to project_team_index_path(project), notice: "No available teams for assigment."
    end
  end

  def assign
    Projects::Teams::CreateRelationContext.new(@current_user, project, params).execute
    redirect_to project_team_index_path(project)
  end

  def resign
    Projects::Teams::RemoveRelationContext.new(@current_user, project, params).execute
    redirect_to project_team_index_path(project)
  end

  protected

  def user_team
    @team ||= UserTeam.find_by_path(params[:id])
  end
end
