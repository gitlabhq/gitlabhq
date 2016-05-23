class Projects::HooksController < Projects::ApplicationController
  # Authorize
  before_action :authorize_admin_project!

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
      redirect_to namespace_project_hooks_path(@project.namespace, @project)
    else
      @hooks = @project.hooks.select(&:persisted?)
      render :index
    end
  end

  def test
    if !@project.empty_repo?
      status, message = TestHookService.new.execute(hook, current_user)

      if status && status >= 200 && status < 400
        flash[:notice] = "钩子执行成功：HTTP #{status}"
      elsif status
        flash[:alert] = "钩子执行成功但返回 HTTP #{status} #{message}"
      else
        flash[:alert] = "钩子执行失败：#{message}"
      end
    else
      flash[:alert] = '钩子执行失败。确保项目已提交。'
    end

    redirect_back_or_default(default: { action: 'index' })
  end

  def destroy
    hook.destroy

    redirect_to namespace_project_hooks_path(@project.namespace, @project)
  end

  private

  def hook
    @hook ||= @project.hooks.find(params[:id])
  end

  def hook_params
    params.require(:hook).permit(
      :build_events,
      :enable_ssl_verification,
      :issues_events,
      :merge_requests_events,
      :note_events,
      :push_events,
      :tag_push_events,
      :token,
      :url
    )
  end
end
