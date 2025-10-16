# frozen_string_literal: true

module Groups
  class StepUpAuthsController < Groups::ApplicationController
    include InternalRedirect

    before_action :require_user!

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
      Feature.enabled?(:omniauth_step_up_auth_for_namespace, current_user) &&
        ::Gitlab::Auth::Oidc::StepUpAuthentication.succeeded?(session, scope: :namespace)
    end

    def redirect_path
      safe_redirect_path(stored_location_for(:redirect)) || group_path(group)
    end
  end
end
