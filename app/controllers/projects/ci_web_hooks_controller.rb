class Projects::CiWebHooksController < Projects::ApplicationController
  before_action :ci_project
  before_action :authorize_admin_project!

  layout "project_settings"

  def index
    @web_hooks = @ci_project.web_hooks
    @web_hook = Ci::WebHook.new
  end

  def create
    @web_hook = @ci_project.web_hooks.new(web_hook_params)
    @web_hook.save

    if @web_hook.valid?
      redirect_to namespace_project_ci_web_hooks_path(@project.namespace, @project)
    else
      @web_hooks = @ci_project.web_hooks.select(&:persisted?)
      render :index
    end
  end

  def test
    Ci::TestHookService.new.execute(hook, current_user)

    redirect_back_or_default(default: { action: 'index' })
  end

  def destroy
    hook.destroy

    redirect_to namespace_project_ci_web_hooks_path(@project.namespace, @project)
  end

  private

  def hook
    @web_hook ||= @ci_project.web_hooks.find(params[:id])
  end

  def web_hook_params
    params.require(:web_hook).permit(:url)
  end
end
