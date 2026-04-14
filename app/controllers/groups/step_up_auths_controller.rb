# frozen_string_literal: true

module Groups
  class StepUpAuthsController < Groups::ApplicationController
    include InternalRedirect

    before_action :require_user!
    skip_before_action :enforce_step_up_auth_for_namespace

    feature_category :system_access

    def new
      unless step_up_auth_succeeded?
        store_location_for(:redirect, redirect_path)
        return
      end

      redirect_to redirect_path, notice: _('Step-up authentication already completed')
    end

    private

    def require_user!
      render_404 unless current_user
    end

    def step_up_auth_succeeded?
      return false if Feature.disabled?(:omniauth_step_up_auth_for_namespace, group)

      provider_name = group.step_up_auth_required_oauth_provider_from_self_or_inherited
      return false unless provider_name

      ::Gitlab::Auth::Oidc::StepUpAuthentication
        .build_flow(
          provider: provider_name,
          session: session,
          scope: ::Gitlab::Auth::Oidc::StepUpAuthentication::SCOPE_NAMESPACE
        )
        .succeeded?
    end

    def redirect_path
      safe_redirect_path(stored_location_for(:redirect)) || group_path(group)
    end
  end
end
