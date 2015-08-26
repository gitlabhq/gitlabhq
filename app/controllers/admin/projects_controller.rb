class Admin::ProjectsController < Admin::ApplicationController
  before_action :project, only: [:show, :transfer]
  before_action :group, only: [:show, :transfer]
  before_action :repository, only: [:show, :transfer]

  def index
    @projects = Project.all
    @projects = @projects.in_namespace(params[:namespace_id]) if params[:namespace_id].present?
    @projects = @projects.where("visibility_level IN (?)", params[:visibility_levels]) if params[:visibility_levels].present?
    @projects = @projects.with_push if params[:with_push].present?
    @projects = @projects.abandoned if params[:abandoned].present?
    @projects = @projects.non_archived unless params[:with_archived].present?
    @projects = @projects.search(params[:name]) if params[:name].present?
    @projects = @projects.sort(@sort = params[:sort])
    @projects = @projects.includes(:namespace).order("namespaces.path, projects.name ASC").page(params[:page]).per(PER_PAGE)
  end

  def show
    if @group
      @group_members = @group.members.order("access_level DESC").page(params[:group_members_page]).per(PER_PAGE)
    end

    @project_members = @project.project_members.page(params[:project_members_page]).per(PER_PAGE)
  end

  def transfer
    namespace = Namespace.find_by(id: params[:new_namespace_id])
    ::Projects::TransferService.new(@project, current_user, params.dup).execute(namespace)

    @project.reload
    redirect_to admin_namespace_project_path(@project.namespace, @project)
  end

  protected

  def project
    @project = Project.find_with_namespace(
      [params[:namespace_id], '/', params[:id]].join('')
    )
    @project || render_404
  end

  def group
    @group ||= @project.group
  end
end
