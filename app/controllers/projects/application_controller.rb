class Projects::ApplicationController < ApplicationController
  before_action :project
  before_action :repository
  layout 'project'

  def authenticate_user!
    # Restrict access to Projects area only
    # for non-signed users
    if !current_user
      id = params[:project_id] || params[:id]
      project_with_namespace = "#{params[:namespace_id]}/#{id}"
      @project = Project.find_with_namespace(project_with_namespace)

      return if @project && @project.public?
    end

    super
  end

  def require_branch_head
    unless @repository.branch_names.include?(@ref)
      redirect_to(
        namespace_project_tree_path(@project.namespace, @project, @ref),
        notice: "This action is not allowed unless you are on top of a branch"
      )
    end
  end

  private

  def ci_enabled
    return render_404 unless @project.gitlab_ci?
  end

  def ci_project
    @ci_project ||= @project.ensure_gitlab_ci_project
  end
end
