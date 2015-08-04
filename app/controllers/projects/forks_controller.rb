class Projects::ForksController < Projects::ApplicationController
  # Authorize
  before_action :require_non_empty_project
  before_action :authorize_download_code!

  def new
    @namespaces = current_user.manageable_namespaces
    @namespaces.delete(@project.namespace)
  end

  def create
    namespace = Namespace.find(params[:namespace_key])
    @forked_project = ::Projects::ForkService.new(project, current_user, namespace: namespace).execute

    if @forked_project.saved? && @forked_project.forked?
      redirect_to(
        namespace_project_path(@forked_project.namespace, @forked_project),
        notice: 'Project was successfully forked.'
      )
    else
      render :error
    end
  end
end
