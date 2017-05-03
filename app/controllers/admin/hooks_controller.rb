class Admin::HooksController < Admin::ApplicationController
  before_action :hook, only: :edit

  def index
    @hooks = SystemHook.all
    @hook = SystemHook.new
  end

  def create
    @hook = SystemHook.new(hook_params)

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
    if hook.update_attributes(hook_params)
      flash[:notice] = 'System hook was successfully updated.'
      redirect_to admin_hooks_path
    else
      render 'edit'
    end
  end

  def destroy
    hook.destroy

    redirect_to admin_hooks_path
  end

  def test
    data = {
      event_name: "project_create",
      name: "Ruby",
      path: "ruby",
      project_id: 1,
      owner_name: "Someone",
      owner_email: "example@gitlabhq.com"
    }
    hook.execute(data, 'system_hooks')

    redirect_back_or_default
  end

  private

  def hook
    @hook ||= SystemHook.find(params[:id])
  end

  def hook_params
    params.require(:hook).permit(
      :enable_ssl_verification,
      :push_events,
      :tag_push_events,
      :token,
      :url
    )
  end
end
