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
      continue_params[:notice] ||= "The project was successfully forked."

      if @forked_project.import_in_progress?
        redirect_to namespace_project_import_path(@forked_project.namespace, @forked_project, continue: continue_params)
      else
        if continue_params
          redirect_to continue_params[:to], notice: continue_params[:notice]
        else
          redirect_to namespace_project_path(@forked_project.namespace, @forked_project)
        end
      end
    else
      render :error
    end
  end

  private

  def continue_params
    params[:continue].permit(:to, :notice, :notice_now)
  end
end
