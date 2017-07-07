class Projects::ImportsController < Projects::ApplicationController
  include ContinueParams

  # Authorize
  before_action :authorize_admin_project!
  before_action :require_no_repo, only: [:new, :create]
  before_action :redirect_if_progress, only: [:new, :create]
  before_action :redirect_if_no_import, only: :show

  def new
  end

  def create
    @project.import_url = params[:project][:import_url]

    if @project.save
      @project.reload.import_schedule
    end

    redirect_to project_import_path(@project)
  end

  def show
    if @project.import_finished?
      if continue_params
        redirect_to continue_params[:to], notice: continue_params[:notice]
      else
        redirect_to project_path(@project), notice: finished_notice
      end
    elsif @project.import_failed?
      redirect_to new_project_import_path(@project)
    else
      if continue_params && continue_params[:notice_now]
        flash.now[:notice] = continue_params[:notice_now]
      end

      # Render
    end
  end

  private

  def finished_notice
    if @project.forked?
      'The project was successfully forked.'
    else
      'The project was successfully imported.'
    end
  end

  def require_no_repo
    if @project.repository_exists?
      redirect_to project_path(@project)
    end
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
end
