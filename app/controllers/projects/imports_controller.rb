# frozen_string_literal: true

class Projects::ImportsController < Projects::ApplicationController
  include ContinueParams
  include ImportUrlParams

  # Authorize
  before_action :authorize_admin_project!, except: :show
  before_action :require_namespace_project_creation_permission, only: :show
  before_action :require_no_repo, except: :show
  before_action :redirect_if_progress, except: :show
  before_action :redirect_if_no_import, only: :show

  feature_category :importers
  urgency :low

  def new; end

  def create
    @project.import_state.reset.schedule if @project.update(import_params)

    redirect_to project_import_path(@project)
  end

  def show
    if @project.import_finished?
      if continue_params[:to]
        redirect_to continue_params[:to], notice: continue_params[:notice]
      else
        redirect_to project_path(@project), notice: finished_notice
      end
    elsif @project.import_failed?
      redirect_to new_project_import_path(@project)
    else
      flash.now[:notice] = continue_params[:notice_now]
    end
  end

  private

  def finished_notice
    if @project.forked?
      _('The project was successfully forked.')
    else
      _('The project was successfully imported.')
    end
  end

  def require_no_repo
    redirect_to project_path(@project) if @project.repository_exists?
  end

  # Project creation by template uses a different permission model to regular imports
  # https://gitlab.com/gitlab-org/gitlab/-/issues/414046#note_1945586449.
  def require_namespace_project_creation_permission
    if Gitlab::ImportSources.template?(@project.import_type)
      render_404 unless can?(current_user, :create_projects, project.namespace)
    else
      unless can?(current_user, :admin_project, @project) || can?(current_user, :import_projects, @project.namespace)
        render_404
      end
    end
  end

  def redirect_if_progress
    redirect_to project_import_path(@project) if @project.import_in_progress?
  end

  def redirect_if_no_import
    redirect_to project_path(@project) if @project.repository_exists? && @project.no_import?
  end

  def import_params_attributes
    []
  end

  def import_params
    params.require(:project)
      .permit(import_params_attributes)
      .merge(import_url_params)
  end
end

Projects::ImportsController.prepend_mod_with('Projects::ImportsController')
