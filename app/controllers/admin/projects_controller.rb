class Admin::ProjectsController < Admin::ApplicationController
  before_filter :project, only: [:edit, :show, :update, :destroy, :team_update]

  def index
    owner_id = params[:owner_id]
    user = User.find_by_id(owner_id)

    @projects = user ? user.owned_projects : Project.scoped
    @projects = @projects.where(public: true) if params[:public_only].present?
    @projects = @projects.with_push if params[:with_push].present?
    @projects = @projects.abandoned if params[:abandoned].present?
    @projects = @projects.where(namespace_id: nil) if params[:namespace_id] == Namespace.global_id
    @projects = @projects.search(params[:name]) if params[:name].present?
    @projects = @projects.includes(:namespace).order("namespaces.path, projects.name ASC").page(params[:page]).per(20)
  end

  def show
    @repository = @project.repository
  end

  protected

  def project
    id = params[:project_id] || params[:id]

    @project = Project.find_with_namespace(id)
    @project || render_404
  end
end
