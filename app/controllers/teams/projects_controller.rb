class Teams::ProjectsController < Teams::ApplicationController
  def index
    @projects = user_team.projects
    @avaliable_projects = current_user.admin? ? Project.without_team(user_team) : (Project.personal(current_user) + current_user.projects).uniq
  end

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

    redirect_to admin_team_path(user_team), notice: 'Projects was successfully added.'
  end

  def edit
    team_project
  end

  def update
    if user_team.update_project_access(team_project, params[:greatest_project_access])
      redirect_to admin_team_path(user_team), notice: 'Membership was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    user_team.resign_from_project(team_project)
    redirect_to admin_team_path(user_team), notice: 'Project was successfully removed.'
  end

  private

  def team_project
    @project ||= @team.projects.find_by_path(params[:id])
  end

end
