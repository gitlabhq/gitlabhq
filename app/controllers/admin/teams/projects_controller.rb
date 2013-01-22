class Admin::Teams::ProjectsController < Admin::Teams::ApplicationController
  def new
    @projects = Project.scoped
    @projects = @projects.without_team(user_team) if user_team.projects.any?
    #@projects.reject!(&:empty_repo?)
  end

  def create
    unless params[:project_ids].blank?
      project_ids = params[:project_ids]
      access = params[:greatest_project_access]
      user_team.assign_to_projects(project_ids, access)
    end

    redirect_to admin_team_path(user_team), notice: 'Team of users was successfully assgned to projects.'
  end

  def edit
    team_project
  end

  def update
    if user_team.update_project_access(team_project, params[:greatest_project_access])
      redirect_to admin_team_path(user_team), notice: 'Access was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    user_team.resign_from_project(team_project)
    redirect_to admin_team_path(user_team), notice: 'Team of users was successfully reassigned from project.'
  end

  protected

  def team_project
    @project ||= user_team.projects.find_with_namespace(params[:id])
  end

end
