class Admin::ProjectsController < AdminController
  before_filter :project, only: [:edit, :show, :update, :destroy, :team_update]

  def index
    @projects = Project.scoped
    @projects = @projects.search(params[:name]) if params[:name].present?
    @projects = @projects.order("name ASC").page(params[:page]).per(20)
  end

  def show
    @users = User.scoped
    @users = @users.not_in_project(@project) if @project.users.present?
    @users = @users.all
  end

  def edit
  end

  def team_update
    @project.add_users_ids_to_team(params[:user_ids], params[:project_access])

    redirect_to [:admin, @project], notice: 'Project was successfully updated.'
  end

  def update
    owner_id = params[:project].delete(:owner_id)

    if owner_id
      @project.owner = User.find(owner_id)
    end

    if @project.update_attributes(params[:project], as: :admin)
      redirect_to [:admin, @project], notice: 'Project was successfully updated.'
    else
      render action: "edit"
    end
  end

  def destroy
    @project.destroy

    redirect_to projects_url, notice: 'Project was successfully deleted.'
  end
end
