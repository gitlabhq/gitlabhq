class Admin::HooksController < Admin::ApplicationController
  include HooksExecution

  before_action :hook_logs, only: :edit

  def index
    @hooks = SystemHook.all
    @hook = SystemHook.new
  end

  def create
    @hook = SystemHook.new(hook_params.to_h)

    if @hook.save
      redirect_to admin_hooks_path, notice: 'Hook was successfully created.'
    else
      @hooks = SystemHook.all
      render :index
    end
  end

  def edit
  end

  def update
    if hook.update(hook_params)
      flash[:notice] = 'System hook was successfully updated.'
      redirect_to admin_hooks_path
    else
      render 'edit'
    end
  end

  def destroy
    hook.destroy

    redirect_to admin_hooks_path, status: :found
  end

  def test
    result = TestHooks::SystemService.new(hook, current_user, params[:trigger]).execute

    set_hook_execution_notice(result)

    redirect_back_or_default
  end

  private

  def hook
    @hook ||= SystemHook.find(params[:id])
  end

  def hook_logs
    @hook_logs ||= hook.web_hook_logs.recent.page(params[:page])
  end

  def hook_params
    params.require(:hook).permit(
      :enable_ssl_verification,
      :token,
      :url,
      *SystemHook.triggers.values
    )
  end
end
