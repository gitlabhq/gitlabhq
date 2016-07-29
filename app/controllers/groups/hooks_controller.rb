class Groups::HooksController < Groups::ApplicationController
  # Authorize
  before_action :group
  before_action :authorize_admin_group!

  respond_to :html

  layout 'group_settings'

  def index
    @hooks = @group.hooks
    @hook = GroupHook.new
  end

  def create
    @hook = @group.hooks.new(hook_params)
    @hook.save

    if @hook.valid?
      redirect_to group_hooks_path(@group)
    else
      @hooks = @group.hooks.select(&:persisted?)
      render :index
    end
  end

  def test
    if @group.first_non_empty_project
      status, message = TestHookService.new.execute(hook, current_user)

      if status
        flash[:notice] = 'Hook successfully executed.'
      else
        flash[:alert] = "Hook execution failed: #{message}"
      end
    else
      flash[:alert] = 'Hook execution failed. Ensure the group has a project with commits.'
    end

    redirect_back_or_default(default: { action: 'index' })
  end

  def destroy
    hook.destroy

    redirect_to group_hooks_path(@group)
  end

  private

  def hook
    @hook ||= @group.hooks.find(params[:id])
  end

  def hook_params
    params.require(:hook).permit(:url, :push_events, :issues_events,
      :merge_requests_events, :tag_push_events, :note_events,
      :build_events, :enable_ssl_verification)
  end
end
