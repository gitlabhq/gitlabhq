# frozen_string_literal: true

class Admin::ProjectsController < Admin::ApplicationController
  include MembersPresentation

  before_action :project, only: [:show, :transfer, :repository_check, :destroy]
  before_action :group, only: [:show, :transfer]

  def index
    params[:sort] ||= 'latest_activity_desc'
    @sort = params[:sort]
    @projects = Admin::ProjectsFinder.new(params: params, current_user: current_user).execute

    respond_to do |format|
      format.html
      format.json do
        render json: {
          html: view_to_html_string("admin/projects/_projects", projects: @projects)
        }
      end
    end
  end

  # rubocop: disable CodeReuse/ActiveRecord
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
  # rubocop: enable CodeReuse/ActiveRecord

  def destroy
    ::Projects::DestroyService.new(@project, current_user, {}).async_execute
    flash[:notice] = _("Project '%{project_name}' is in the process of being deleted.") % { project_name: @project.full_name }

    redirect_to admin_projects_path, status: :found
  rescue Projects::DestroyService::DestroyError => ex
    redirect_to admin_projects_path, status: :found, alert: ex.message
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def transfer
    namespace = Namespace.find_by(id: params[:new_namespace_id])
    ::Projects::TransferService.new(@project, current_user, params.dup).execute(namespace)

    @project.reset
    redirect_to admin_project_path(@project)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def repository_check
    RepositoryCheck::SingleRepositoryWorker.perform_async(@project.id)

    redirect_to(
      admin_project_path(@project),
      notice: _('Repository check was triggered.')
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

Admin::ProjectsController.prepend_if_ee('EE::Admin::ProjectsController')
