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
      status = TestHookService.new.execute(hook, current_user)

      if status
        flash[:notice] = 'Hook successfully executed.'
      else
        flash[:alert] = 'Hook execution failed. '\
                        'Ensure hook URL is correct and service is up.'
      end
    else
      flash[:alert] = 'Hook execution failed. Ensure the group has a project with commits.'
    end

    redirect_to :back
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
    params.require(:hook).permit(:url, :push_events, :issues_events, :merge_requests_events, :tag_push_events)
  end
end
