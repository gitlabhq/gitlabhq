class Groups::HooksController < Groups::ApplicationController
  include HooksExecution

  # Authorize
  before_action :group
  before_action :authorize_admin_group!
  before_action :check_group_webhooks_available!

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
      service = TestHooks::ProjectService.new(hook, current_user, 'push_events')
      service.project = @group.first_non_empty_project
      result = service.execute

      set_hook_execution_notice(result)
    else
      flash[:alert] = 'Hook execution failed. Ensure the group has a project with commits.'
    end

    redirect_back_or_default(default: { action: 'index' })
  end

  def destroy
    hook.destroy

    redirect_to group_hooks_path(@group), status: 302
  end

  private

  def hook
    @hook ||= @group.hooks.find(params[:id])
  end

  def hook_params
    params.require(:hook).permit(
      :job_events,
      :confidential_issues_events,
      :enable_ssl_verification,
      :issues_events,
      :merge_requests_events,
      :note_events,
      :pipeline_events,
      :push_events,
      :tag_push_events,
      :token,
      :url,
      :wiki_page_events
    )
  end
end
