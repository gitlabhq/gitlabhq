class Admin::Teams::ProjectsController < Admin::Teams::ApplicationController
  def new
    @projects = Project.scoped
    @projects = @projects.without_team(user_team) if user_team.projects.any?
    #@projects.reject!(&:empty_repo?)
  end

  def create
    redirect_to :back if params[:project_ids].blank?

    ::Teams::Projects::CreateRelationContext.new(current_user, user_team, params).execute

    redirect_to admin_team_path(user_team), notice: 'Team of users was successfully assgned to projects.'
  end

  def edit
    team_project
  end

  def update
    if ::Teams::Projects::UpdateRelationContext.new(current_user, user_team, team_project, params).execute
      redirect_to admin_team_path(user_team), notice: 'Access was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    ::Teams::Projects::RemoveRelationContext.new(current_user, user_team, team_project, params).execute
    redirect_to admin_team_path(user_team), notice: 'Team of users was successfully reassigned from project.'
  end

  protected

  def team_project
    @project ||= user_team.projects.find_with_namespace(params[:id])
  end

end
