# frozen_string_literal: true

# Enforces step-up authentication requirements for namespace access
#
# This controller concern ensures users complete step-up authentication
# before accessing group/namespace resources that require additional authentication.
# Include this module in group and project controllers to enforce the authentication check.
#
# @example
#   class Groups::ApplicationController < ApplicationController
#     include EnforcesStepUpAuthenticationForNamespace
#
#     before_action :enforce_step_up_auth_for_group
#
#     private
#
#     def enforce_step_up_auth_for_group
#       enforce_step_up_auth_for(@group) if @group
#     end
#   end
module EnforcesStepUpAuthenticationForNamespace
  extend ActiveSupport::Concern

  private

  # Looks up a namespace by ID and enforces step-up authentication
  # Raises ActiveRecord::RecordNotFound if namespace_id is provided but namespace not found
  def enforce_step_up_auth_for_namespace_id(namespace_id)
    namespace =
      Namespace.find_by_id(namespace_id) ||
      Namespace.find_by_full_path(namespace_id)
    enforce_step_up_auth_for(namespace)
  end

  def enforce_step_up_auth_for(namespace)
    return if Feature.disabled?(:omniauth_step_up_auth_for_namespace, namespace)

    # Don't proceed if a render/redirect has already been performed
    return if performed?

    # Security check: Always raise error for nil namespace BEFORE any other checks
    # This prevents bypassing step-up auth enforcement by passing invalid namespace
    raise ActiveRecord::RecordNotFound, 'Namespace not found' if namespace.blank?

    return unless step_up_auth_supported_for_namespace?(namespace)
    return unless step_up_auth_required_for_namespace?(namespace)
    return if step_up_auth_succeeded_for_namespace?

    handle_failed_step_up_auth_for_namespace(namespace)
  end

  def step_up_auth_supported_for_namespace?(namespace)
    # Step-up auth is only meaningful for authenticated users
    # If there's no current_user, let the normal authentication flow handle it
    return false unless current_user

    namespace.present? &&
      namespace.is_a?(Group) &&
      namespace.try(:step_up_auth_required_oauth_provider).present?
  end

  def step_up_auth_required_for_namespace?(namespace)
    ::Gitlab::Auth::Oidc::StepUpAuthentication.enabled_for_provider?(
      provider_name: namespace.step_up_auth_required_oauth_provider,
      scope: ::Gitlab::Auth::Oidc::StepUpAuthentication::SCOPE_NAMESPACE
    )
  end

  def step_up_auth_succeeded_for_namespace?
    ::Gitlab::Auth::Oidc::StepUpAuthentication.succeeded?(
      session,
      scope: ::Gitlab::Auth::Oidc::StepUpAuthentication::SCOPE_NAMESPACE
    )
  end

  def handle_failed_step_up_auth_for_namespace(namespace)
    redirect_to(new_group_step_up_auth_path(namespace), notice: build_namespace_step_up_auth_notice)
  end

  def build_namespace_step_up_auth_notice
    notice_message = _('Step-up authentication required.')

    documentation_links = documentation_links_for_failed_step_up_auth_providers(
      ::Gitlab::Auth::Oidc::StepUpAuthentication::SCOPE_NAMESPACE.to_s
    )
    return notice_message if documentation_links.blank?

    links_sentence = helpers.to_sentence(documentation_links)

    helpers.safe_join([
      notice_message,
      ' ',
      _('Learn more about authentication requirements: '),
      links_sentence,
      '.'
    ])
  end

  def documentation_links_for_failed_step_up_auth_providers(scope)
    # Get the list of failed step-up auth flows from the session
    ::Gitlab::Auth::Oidc::StepUpAuthentication
      .failed_step_up_auth_flows(session, scope: scope)
      .filter_map do |flow|
        helpers.step_up_auth_documentation_link(flow)
      end
  end
end
