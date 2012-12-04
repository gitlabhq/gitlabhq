class Admin::ProjectsController < AdminController
  before_filter :project, only: [:edit, :show, :update, :destroy, :team_update]

  def index
    @projects = Project.scoped
    @projects = @projects.where(namespace_id: params[:namespace_id]) if params[:namespace_id].present?
    @projects = @projects.where(namespace_id: nil) if params[:namespace_id] == Namespace.global_id
    @projects = @projects.search(params[:name]) if params[:name].present?
    @projects = @projects.includes(:namespace).order("namespaces.path, projects.name ASC").page(params[:page]).per(20)
  end

  def show
    @users = User.active
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
    status = ProjectUpdateContext.new(project, current_user, params).execute(:admin)

    if status
      redirect_to [:admin, @project], notice: 'Project was successfully updated.'
    else
      render action: "edit"
    end
  end

  def destroy
    @project.destroy

    redirect_to admin_projects_path, notice: 'Project was successfully deleted.'
  end

  protected

  def project
    id = params[:project_id] || params[:id]

    @project = Project.find_with_namespace(id)
    @project || render_404
  end
end
