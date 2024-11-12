# frozen_string_literal: true

class Projects::HooksController < Projects::ApplicationController
  include ::WebHooks::HookActions

  # Authorize
  before_action :authorize_read_hook!, only: [:index, :show]
  before_action :authorize_admin_hook!, except: [:index, :show]
  before_action -> { check_rate_limit!(:web_hook_test, scope: [@project, current_user]) }, only: :test

  respond_to :html

  layout "project_settings"

  urgency :low, [:test]

  def test
    trigger = params.fetch(:trigger, 'push_events')
    result = TestHooks::ProjectService.new(hook, current_user, trigger).execute

    set_hook_execution_notice(result)

    redirect_back_or_default(default: { action: :index })
  end

  private

  def relation
    @project.hooks
  end

  def hook
    @hook ||= @project.hooks.find(params[:id])
  end

  def trigger_values
    ProjectHook.triggers.values
  end

  def authorize_admin_hook!
    render_404 unless can?(current_user, :admin_web_hook, project)
  end

  def authorize_read_hook!
    render_404 unless can?(current_user, :read_web_hook, project)
  end
end
