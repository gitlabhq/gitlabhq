class Projects::ForksController < Projects::ApplicationController
  # Authorize
  before_filter :authorize_download_code!
  before_filter :require_non_empty_project

  def new
    @namespaces = current_user.manageable_namespaces
    @namespaces.delete(@project.namespace)
  end

  def create
    namespace = Namespace.find(params[:namespace_id])
    @forked_project = ::Projects::ForkService.new(project, current_user, namespace: namespace).execute

    if @forked_project.saved? && @forked_project.forked?
      redirect_to(@forked_project, notice: 'Project was successfully forked.')
    else
      @title = 'Fork project'
      render :error
    end
  end
end
