class Teams::ProjectsController < Teams::ApplicationController
  def index
    @projects = @user_team.projects
    @avaliable_projects = current_user.admin? ? Project.without_team(@user_team) : (Project.personal(current_user) + current_user.projects).uniq
  end

  def new
  end

  def create
  end

  def edit
  end

  def update
  end

  def destroy
  end
end
