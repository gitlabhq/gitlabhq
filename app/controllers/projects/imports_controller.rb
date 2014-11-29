class Projects::ImportsController < Projects::ApplicationController
  # Authorize
  before_filter :authorize_admin_project!
  before_filter :require_no_repo
  before_filter :redirect_if_progress, except: :show

  def new
  end

  def create
    @project.import_url = params[:project][:import_url]

    if @project.save
      @project.reload

      if @project.import_failed?
        @project.import_retry
      else
        @project.import_start
      end
    end

    redirect_to project_import_path(@project)
  end

  def show
    unless @project.import_in_progress?
      if @project.import_finished?
        redirect_to(@project) and return
      else
        redirect_to new_project_import_path(@project) and return
      end
    end
  end

  private

  def require_no_repo
    if @project.repository_exists?
      redirect_to(@project) and return
    end
  end

  def redirect_if_progress
    if @project.import_in_progress?
      redirect_to project_import_path(@project) and return
    end
  end
end
