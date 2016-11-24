class Admin::ProjectsController < Admin::ApplicationController
  before_action :project, only: [:show, :transfer, :repository_check]
  before_action :group, only: [:show, :transfer]

  def index
    @projects = Project.all
    @projects = @projects.in_namespace(params[:namespace_id]) if params[:namespace_id].present?
    @projects = @projects.where(visibility_level: params[:visibility_level]) if params[:visibility_level].present?
    @projects = @projects.with_push if params[:with_push].present?
    @projects = @projects.abandoned if params[:abandoned].present?
    @projects = @projects.where(last_repository_check_failed: true) if params[:last_repository_check_failed].present?
    @projects = @projects.non_archived unless params[:archived].present?
    @projects = @projects.personal(current_user) if params[:personal].present?
    @projects = @projects.search(params[:name]) if params[:name].present?
    @projects = @projects.sort(@sort = params[:sort])
    @projects = @projects.includes(:namespace).order("namespaces.path, projects.name ASC").page(params[:page])
  end

  def show
    if @group
      @group_members = @group.members.order("access_level DESC").page(params[:group_members_page])
    end

    @project_members = @project.members.page(params[:project_members_page])
    @requesters = AccessRequestsFinder.new(@project).execute(current_user)
  end

  def transfer
    namespace = Namespace.find_by(id: params[:new_namespace_id])
    ::Projects::TransferService.new(@project, current_user, params.dup).execute(namespace)

    @project.reload
    redirect_to admin_namespace_project_path(@project.namespace, @project)
  end

  def repository_check
    RepositoryCheck::SingleRepositoryWorker.perform_async(@project.id)

    redirect_to(
      admin_namespace_project_path(@project.namespace, @project),
      notice: 'Repository check was triggered.'
    )
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
