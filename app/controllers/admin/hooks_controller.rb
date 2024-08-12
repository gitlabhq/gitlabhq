# frozen_string_literal: true

class Admin::HooksController < Admin::ApplicationController
  include ::WebHooks::HookActions

  urgency :low, [:test]

  before_action :not_found, unless: -> { system_hooks? }

  def test
    result = TestHooks::SystemService.new(hook, current_user, params.permit(:trigger)[:trigger]).execute

    set_hook_execution_notice(result)

    redirect_back_or_default
  end

  private

  def relation
    SystemHook
  end

  def hook
    @hook ||= SystemHook.find(params.permit(:id)[:id])
  end

  def hook_param_names
    %i[enable_ssl_verification name description token url]
  end

  def trigger_values
    SystemHook.triggers.values
  end

  def system_hooks?
    !Gitlab.com? # rubocop:disable Gitlab/AvoidGitlabInstanceChecks -- Not related to SaaS offerings
  end
end
