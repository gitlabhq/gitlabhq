class Projects::ImportsController < Projects::ApplicationController
  # Authorize
  before_action :authorize_admin_project!
  before_action :require_no_repo
  before_action :redirect_if_progress, except: :show

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

    redirect_to namespace_project_import_path(@project.namespace, @project)
  end

  def show
    unless @project.import_in_progress?
      if @project.import_finished?
        redirect_to(project_path(@project)) and return
      else
        redirect_to(new_namespace_project_import_path(@project.namespace,
                                                      @project)) and return
      end
    end
  end

  private

  def require_no_repo
    if @project.repository_exists? && !@project.import_in_progress?
      redirect_to(namespace_project_path(@project.namespace, @project)) and return
    end
  end

  def redirect_if_progress
    if @project.import_in_progress?
      redirect_to namespace_project_import_path(@project.namespace, @project) &&
        return
    end
  end
end
