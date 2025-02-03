# frozen_string_literal: true

class Admin::ProjectsController < Admin::ApplicationController
  include MembersPresentation

  before_action :project, only: [:show, :transfer, :repository_check, :destroy, :edit, :update]
  before_action :group, only: [:show, :transfer]

  feature_category :groups_and_projects, [:index, :show, :transfer, :destroy, :edit, :update]
  feature_category :source_code_management, [:repository_check]

  def index
    params[:sort] ||= 'latest_activity_desc'
    @sort = params[:sort]

    params[:archived] = true if params[:last_repository_check_failed].present? && params[:archived].nil?

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
    flash[:toast] = format(_("Project '%{project_name}' is being deleted."), project_name: @project.full_name)

    redirect_to admin_projects_path, status: :found
  rescue Projects::DestroyService::DestroyError => e
    redirect_to admin_projects_path, status: :found, alert: e.message
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def transfer
    namespace = Namespace.find_by(id: params[:new_namespace_id])
    ::Projects::TransferService.new(@project, current_user, params.dup).execute(namespace)

    flash[:alert] = @project.errors[:new_namespace].first if @project.errors[:new_namespace].present?

    @project.reset
    redirect_to admin_project_path(@project)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def edit; end

  def update
    result = ::Projects::UpdateService.new(@project, current_user, project_params).execute

    if result[:status] == :success
      unless Gitlab::Utils.to_boolean(project_params['runner_registration_enabled'])
        Ci::Runners::ResetRegistrationTokenService.new(@project, current_user).execute
      end

      redirect_to [:admin, @project],
        notice: format(_("Project '%{project_name}' was successfully updated."), project_name: @project.name)
    else
      render "edit"
    end
  end

  def repository_check
    RepositoryCheck::SingleRepositoryWorker.perform_async(@project.id) # rubocop:disable CodeReuse/Worker

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

  def project_params
    params.require(:project).permit(allowed_project_params)
  end

  def allowed_project_params
    [
      :description,
      :name,
      :runner_registration_enabled
    ]
  end
end

Admin::ProjectsController.prepend_mod_with('Admin::ProjectsController')
