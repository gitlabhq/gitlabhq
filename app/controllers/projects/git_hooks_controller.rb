class Projects::GitHooksController < Projects::ApplicationController
  # Authorize
  before_filter :authorize_admin_project!

  respond_to :html

  layout "project_settings"

  def index
    project.create_git_hook unless project.git_hook

    @pre_receive_hook = project.git_hook
  end

  def update
    @pre_receive_hook = project.git_hook
    @pre_receive_hook.update_attributes(params[:git_hook])

    if @pre_receive_hook.valid?
      redirect_to project_git_hooks_path(@project)
    else
      render :index
    end
  end
end
