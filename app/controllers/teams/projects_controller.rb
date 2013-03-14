class Teams::ProjectsController < Teams::ApplicationController
  def create
    redirect_to :back if params[:project_ids].blank?

    project_ids = params[:project_ids]
    access = params[:greatest_project_access]

    # Reject non-allowed projects
    allowed_project_ids = current_user.owned_projects.map(&:id)
    project_ids.select! { |id| allowed_project_ids.include?(id.to_i) }

    # Assign projects to team
    user_team.assign_to_projects(project_ids, access)

    redirect_to edit_team_path(user_team), notice: 'Team of users was successfully assigned to projects.'
  end

  def edit
    team_project
  end

  def update
    if user_team.update_project_access(team_project, params[:greatest_project_access])
      redirect_to edit_team_path(user_team), notice: 'Access was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    user_team.resign_from_project(team_project)
    redirect_to team_projects_path(user_team), notice: 'Team of users was successfully reassigned from project.'
  end

  private

  def team_project
    @project ||= user_team.projects.find_with_namespace(params[:id])
  end
end
