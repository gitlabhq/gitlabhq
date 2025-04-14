# frozen_string_literal: true

# Enforces step-up authentication requirements for admin access
#
# This controller concern ensures users complete step-up authentication
# before accessing admin functionality. Include this module in admin
# controllers to enforce the authentication check.
#
# @example
#   class Admin::ApplicationController < ApplicationController
#     include EnforcesStepUpAuthentication
#   end
module EnforcesStepUpAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :enforce_step_up_authentication
  end

  private

  def enforce_step_up_authentication
    return if Feature.disabled?(:omniauth_step_up_auth_for_admin_mode, current_user)

    return if step_up_auth_disabled_for_admin_mode?
    return if step_up_auth_flow_state_success?

    handle_failed_authentication
  end

  def step_up_auth_disabled_for_admin_mode?
    !::Gitlab::Auth::Oidc::StepUpAuthentication.enabled_by_config?
  end

  def step_up_auth_flow_state_success?
    ::Gitlab::Auth::Oidc::StepUpAuthentication.succeeded?(session)
  end

  def handle_failed_authentication
    # We need to disable (reset) the admin mode in order to redirect the user to the admin login page.
    # If we do not do this, the Admin::SessionsController will thinks that the admin mode has been successfully reached
    # and will redirect the user to the path 'admin/dashboard'. But, the check in this EnforceStepUpAuthentication
    # will fail again and redirect the user to the login page which will end up in a loop.
    disable_admin_mode

    redirect_to(new_admin_session_path, notice: _('Step-up auth not successful'))
  end

  def disable_admin_mode
    current_user_mode.disable_admin_mode! if current_user_mode.admin_mode?
  end
end
