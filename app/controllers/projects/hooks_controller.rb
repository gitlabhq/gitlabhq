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
    result = TestHooks::ProjectService.new(hook, current_user, trigger_param).execute

    set_hook_execution_notice(result)

    redirect_back_or_default(default: { action: :index })
  end

  private

  def relation
    @project.hooks
  end

  def hook_container
    @project
  end

  def hook
    @hook ||= @project.hooks.find(id_param)
  end

  def id_param
    params.permit(:id)[:id]
  end

  def trigger_param
    params.permit(:trigger).fetch(:trigger, 'push_events')
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
