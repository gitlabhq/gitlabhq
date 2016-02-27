class Projects::ForksController < Projects::ApplicationController
  # Authorize
  before_action :require_non_empty_project
  before_action :authorize_download_code!

  def index
    base_query = project.forks.includes(:creator)

    @forks = if current_user
               base_query.where('projects.visibility_level IN (?) OR projects.id IN (?)',
                                Project::PUBLIC,
                                current_user.authorized_projects.pluck(:id))
             else
               base_query.where('projects.visibility_level = ?', Project::PUBLIC)
             end

    @total_forks_count   = base_query.size
    @private_forks_count = @total_forks_count - @forks.size
    @public_forks_count  = @total_forks_count - @private_forks_count

    @sort  = params[:sort] || 'id_desc'
    @forks = @forks.order_by(@sort).page(params[:page]).per(PER_PAGE)
  end

  def new
    @namespaces = current_user.manageable_namespaces
    @namespaces.delete(@project.namespace)
  end

  def create
    namespace = Namespace.find(params[:namespace_key])

    @forked_project = namespace.projects.find_by(path: project.path)
    @forked_project = nil unless @forked_project && @forked_project.forked_from_project == project

    @forked_project ||= ::Projects::ForkService.new(project, current_user, namespace: namespace).execute

    if @forked_project.saved? && @forked_project.forked?
      if @forked_project.import_in_progress?
        redirect_to namespace_project_import_path(@forked_project.namespace, @forked_project, continue: continue_params)
      else
        if continue_params
          redirect_to continue_params[:to], notice: continue_params[:notice]
        else
          redirect_to namespace_project_path(@forked_project.namespace, @forked_project), notice: "The project '#{@forked_project.name}' was successfully forked."
        end
      end
    else
      render :error
    end
  end

  private

  def continue_params
    continue_params = params[:continue]
    if continue_params
      continue_params.permit(:to, :notice, :notice_now)
    else
      nil
    end
  end
end
