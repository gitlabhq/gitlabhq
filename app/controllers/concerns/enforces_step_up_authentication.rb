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

    return handle_expired_step_up_authentication if step_up_authentication_expired?

    handle_failed_authentication
  end

  def step_up_auth_disabled_for_admin_mode?
    !::Gitlab::Auth::Oidc::StepUpAuthentication.enabled_by_config?
  end

  def step_up_auth_flow_state_success?
    ::Gitlab::Auth::Oidc::StepUpAuthentication.succeeded?(session)
  end

  def step_up_authentication_expired?
    ::Gitlab::Auth::Oidc::StepUpAuthentication.step_up_session_expired?(session)
  end

  def handle_expired_step_up_authentication
    # Disable admin mode and clean up expired step-up session
    disable_admin_mode
    ::Gitlab::Auth::Oidc::StepUpAuthentication.disable_step_up_authentication!(session: session)

    redirect_to(
      new_admin_session_path,
      notice: _('Step-up authentication session has expired. Please authenticate again.')
    )
  end

  def handle_failed_authentication
    # We need to disable (reset) the admin mode in order to redirect the user to the admin login page.
    # If we do not do this, the Admin::SessionsController will thinks that the admin mode has been successfully reached
    # and will redirect the user to the path 'admin/dashboard'. But, the check in this EnforceStepUpAuthentication
    # will fail again and redirect the user to the login page which will end up in a loop.
    disable_admin_mode

    redirect_to(new_admin_session_path, notice: build_step_up_auth_notice)
  end

  def disable_admin_mode
    current_user_mode.disable_admin_mode! if current_user_mode.admin_mode?
  end

  def build_step_up_auth_notice
    notice_message = s_('AdminMode|Step-up authentication failed.')

    documentation_links = documentation_links_for_failed_step_up_auth_providers
    return notice_message if documentation_links.blank?

    links_sentence = helpers.to_sentence(documentation_links)

    helpers.safe_join([
      notice_message,
      ' ',
      s_('AdminMode|Learn more about authentication requirements: '),
      links_sentence,
      '.'
    ])
  end

  def documentation_links_for_failed_step_up_auth_providers(scope = 'admin_mode')
    # Get the list of failed step-up auth flows from the session
    ::Gitlab::Auth::Oidc::StepUpAuthentication
      .failed_step_up_auth_flows(session, scope: scope)
      .filter_map do |flow|
        helpers.step_up_auth_documentation_link(flow)
      end
  end
end
