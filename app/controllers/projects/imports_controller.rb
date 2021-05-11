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

  def new
  end

  def create
    if @project.update(import_params)
      @project.import_state.reset.schedule
    end

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
    if @project.repository_exists?
      redirect_to project_path(@project)
    end
  end

  def require_namespace_project_creation_permission
    render_404 unless can?(current_user, :admin_project, @project) || can?(current_user, :create_projects, @project.namespace)
  end

  def redirect_if_progress
    if @project.import_in_progress?
      redirect_to project_import_path(@project)
    end
  end

  def redirect_if_no_import
    if @project.repository_exists? && @project.no_import?
      redirect_to project_path(@project)
    end
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
