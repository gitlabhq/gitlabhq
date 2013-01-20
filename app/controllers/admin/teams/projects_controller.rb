class Admin::Teams::ProjectsController < Admin::Teams::ApplicationController
  before_filter :team_project, only: [:edit, :destroy, :update]

  def new
    @projects = Project.scoped
    @projects = @projects.without_team(@team) if @team.projects.any?
    #@projects.reject!(&:empty_repo?)
  end

  def create
    unless params[:project_ids].blank?
      project_ids = params[:project_ids]
      access = params[:greatest_project_access]
      @team.assign_to_projects(project_ids, access)
    end

    redirect_to admin_team_path(@team), notice: 'Projects was successfully added.'
  end

  def edit
  end

  def update
    if @team.update_project_access(@project, params[:greatest_project_access])
      redirect_to admin_team_path(@team), notice: 'Membership was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @team.resign_from_project(@project)
    redirect_to admin_team_path(@team), notice: 'Project was successfully removed.'
  end

  private

  def team_project
    @project = @team.projects.find_by_path(params[:id])
  end

end
