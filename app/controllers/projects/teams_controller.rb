class Projects::TeamsController < Projects::ApplicationController

  def available
    @teams = current_user.is_admin? ? UserTeam.scoped : current_user.user_teams
    @teams = @teams.without_project(project)
    unless @teams.any?
      redirect_to project_team_index_path(project), notice: "No avaliable teams for assigment."
    end
  end

  def assign
    unless params[:team_id].blank?
      team = UserTeam.find(params[:team_id])
      access = params[:greatest_project_access]
      team.assign_to_project(project, access)
    end
    redirect_to project_team_index_path(project)
  end

  def resign
    team = project.user_teams.find_by_path(params[:id])
    team.resign_from_project(project)

    redirect_to project_team_index_path(project)
  end

end
