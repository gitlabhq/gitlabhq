class Admin::ProjectsController < Admin::ApplicationController
  before_filter :project, only: [:show, :transfer]
  before_filter :group, only: [:show, :transfer]
  before_filter :repository, only: [:show, :transfer]

  def index
    owner_id = params[:owner_id]
    user = User.find_by(id: owner_id)

    @projects = user ? user.owned_projects : Project.all
    @projects = @projects.where("visibility_level IN (?)", params[:visibility_levels]) if params[:visibility_levels].present?
    @projects = @projects.with_push if params[:with_push].present?
    @projects = @projects.abandoned if params[:abandoned].present?
    @projects = @projects.search(params[:name]) if params[:name].present?
    @projects = @projects.includes(:namespace).order("namespaces.path, projects.name ASC").page(params[:page]).per(20)
  end

  def show
  end

  def transfer
    result = ::Projects::TransferService.new(@project, current_user, project: params).execute(:admin)

    if result
      redirect_to [:admin, @project]
    else
      render :show
    end
  end

  protected

  def project
    id = params[:project_id] || params[:id]

    @project = Project.find_with_namespace(id)
    @project || render_404
  end

  def group
    @group ||= project.group
  end

  def repository
    @repository ||= project.repository
  end
end
