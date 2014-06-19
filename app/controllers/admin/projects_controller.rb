class Admin::ProjectsController < Admin::ApplicationController
  before_filter :project, only: [:show, :transfer]
  before_filter :group, only: [:show, :transfer]
  before_filter :repository, only: [:show, :transfer]

  def index
    @projects = Project.all
    @projects = @projects.where(namespace_id: params[:namespace_id]) if params[:namespace_id].present?
    @projects = @projects.where("visibility_level IN (?)", params[:visibility_levels]) if params[:visibility_levels].present?
    @projects = @projects.with_push if params[:with_push].present?
    @projects = @projects.abandoned if params[:abandoned].present?
    @projects = @projects.search(params[:name]) if params[:name].present?
    @projects = @projects.sort(@sort = params[:sort])
    @projects = @projects.includes(:namespace).order("namespaces.path, projects.name ASC").page(params[:page]).per(20)
  end

  def show
    if @group
      @group_members = @group.members.order("group_access DESC").page(params[:group_members_page]).per(30)
    end

    @project_members = @project.users_projects.page(params[:project_members_page]).per(30)
  end

  def transfer
    ::Projects::TransferService.new(@project, current_user, params.dup).execute

    redirect_to [:admin, @project.reload]
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
