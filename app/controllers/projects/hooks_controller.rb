# frozen_string_literal: true

class Projects::HooksController < Projects::ApplicationController
  include ::WebHooks::HookActions

  # Authorize
  before_action :authorize_admin_project!, except: :destroy
  before_action :authorize_destroy_project_hook!, only: :destroy
  before_action -> { check_rate_limit!(:project_testing_hook, scope: [@project, current_user]) }, only: :test

  respond_to :html

  layout "project_settings"

  urgency :low, [:test]

  def test
    trigger = params.fetch(:trigger, ::ProjectHook.triggers.each_value.first.to_s)
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

  def authorize_destroy_project_hook!
    render_404 unless can?(current_user, :destroy_web_hook, hook)
  end
end
