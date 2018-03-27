class Admin::ProjectsController < Admin::ApplicationController
  include MembersPresentation

  before_action :project, only: [:show, :transfer, :repository_check]
  before_action :group, only: [:show, :transfer]

  def index
    params[:sort] ||= 'latest_activity_desc'
    @sort = params[:sort]
    @projects = Admin::ProjectsFinder.new(params: params, current_user: current_user).execute

    respond_to do |format|
      format.html
      format.json do
        render json: {
          html: view_to_html_string("admin/projects/_projects", locals: { projects: @projects })
        }
      end
    end
  end

  def show
    if @group
      @group_members = present_members(
        @group.members.order("access_level DESC").page(params[:group_members_page]))
    end

    @project_members = present_members(
      @project.members.page(params[:project_members_page]))
    @requesters = present_members(
      AccessRequestsFinder.new(@project).execute(current_user))
  end

  def transfer
    namespace = Namespace.find_by(id: params[:new_namespace_id])
    ::Projects::TransferService.new(@project, current_user, params.dup).execute(namespace)

    @project.reload
    redirect_to admin_project_path(@project)
  end

  def repository_check
    RepositoryCheck::SingleRepositoryWorker.perform_async(@project.id)

    redirect_to(
      admin_project_path(@project),
      notice: 'Repository check was triggered.'
    )
  end

  protected

  def project
    @project = Project.find_by_full_path(
      [params[:namespace_id], '/', params[:id]].join('')
    )
    @project || render_404
  end

  def group
    @group ||= @project.group
  end
end
