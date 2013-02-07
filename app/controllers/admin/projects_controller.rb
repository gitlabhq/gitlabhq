class Admin::ProjectsController < Admin::ApplicationController
  before_filter :project, only: [:edit, :show, :update, :destroy, :team_update]

  def index
    @projects = Project.scoped
    @projects = @projects.where(namespace_id: params[:namespace_id]) if params[:namespace_id].present?
    @projects = @projects.where(public: true) if params[:public_only].present?
    @projects = @projects.with_push if params[:with_push].present?
    @projects = @projects.abandoned if params[:abandoned].present?
    @projects = @projects.where(namespace_id: nil) if params[:namespace_id] == Namespace.global_id
    @projects = @projects.search(params[:name]) if params[:name].present?
    @projects = @projects.includes(:namespace).order("namespaces.path, projects.name ASC").page(params[:page]).per(20)
  end

  def show
    @repository = @project.repository
    @users = User.active
    @users = @users.not_in_project(@project) if @project.users.present?
    @users = @users.all
  end

  def edit
  end

  def team_update
    @project.team.add_users_ids(params[:user_ids], params[:project_access])

    redirect_to [:admin, @project], notice: 'Project was successfully updated.'
  end

  def update
    project.creator = current_user unless project.creator

    status = ::Projects::UpdateContext.new(project, current_user, params).execute(:admin)

    if status
      redirect_to [:admin, @project], notice: 'Project was successfully updated.'
    else
      render action: "edit"
    end
  end

  def destroy
    # Delete team first in order to prevent multiple gitolite calls
    @project.team.truncate

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
