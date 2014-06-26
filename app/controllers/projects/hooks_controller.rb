class Projects::HooksController < Projects::ApplicationController
  # Authorize
  before_filter :authorize_admin_project!

  respond_to :html

  layout "project_settings"

  def index
    @hooks = @project.hooks
    @hook = ProjectHook.new
  end

  def create
    @hook = @project.hooks.new(hook_params)
    @hook.save

    if @hook.valid?
      redirect_to project_hooks_path(@project)
    else
      @hooks = @project.hooks.select(&:persisted?)
      render :index
    end
  end

  def test
    TestHookService.new.execute(hook, current_user)

    redirect_to :back
  end

  def destroy
    hook.destroy

    redirect_to project_hooks_path(@project)
  end

  private

  def hook
    @hook ||= @project.hooks.find(params[:id])
  end

  def hook_params
    params.require(:hook).permit(:url, :push_events, :issues_events, :merge_requests_events, :tag_push_events)
  end
end
