# frozen_string_literal: true

module Observability
  # Shared POST #create action for the backend-for-frontend (BFF) per-user
  # SigNoz session endpoints. Mints per-user tokens via O11yBffSession and
  # returns them as JSON for app.vue to inject into the embedded iframe.
  #
  # Group- and project-scoped controllers differ only in how they resolve
  # observability_setting and the feature-flag/authorization actor -- see
  # the NotImplementedError methods below.
  module SessionActions
    extend ActiveSupport::Concern
    include Gitlab::Utils::StrongMemoize

    included do
      before_action :authenticate_user!
      before_action :ensure_bff_enabled!
      before_action :authorize_read_observability!
      before_action :check_bff_session_rate_limit!

      feature_category :observability
      urgency :low
    end

    def create
      return render json: { error: 'observability not configured' }, status: :not_found unless observability_setting

      tokens = ::Observability::O11yBffSession.generate_tokens(
        o11y_settings: observability_setting,
        user: current_user,
        access_resource: access_resource
      )

      if tokens.present? && tokens[:accessJwt].present?
        render json: { auth_tokens: { access_jwt: tokens[:accessJwt], refresh_jwt: tokens[:refreshJwt] } }
      else
        render json: { error: 'authentication failed' }, status: :unauthorized
      end
    end

    private

    # This endpoint mints a Doorkeeper access token and performs an external
    # HTTP call (the SigNoz BFF exchange) on every request, so it is
    # rate-limited per-user in addition to the authorization checks above.
    def check_bff_session_rate_limit!
      check_rate_limit!(:observability_bff_session, scope: current_user)
    end

    # Subclasses must define:
    #   observability_setting - the Observability::GroupO11ySetting (or nil)
    def observability_setting
      raise NotImplementedError
    end

    # Subclasses must define:
    #   ensure_bff_enabled! - checks the observability_per_user_bff_auth flag
    #                         against the correct group and render_404s if disabled
    def ensure_bff_enabled!
      raise NotImplementedError
    end

    # Subclasses must define:
    #   authorize_read_observability! - checks read_observability_portal
    def authorize_read_observability!
      raise NotImplementedError
    end

    # Subclasses must define:
    #   access_resource - the subject the read_observability_portal Ability
    #                     check was evaluated against (group or project), so
    #                     O11yBffSession resolves the SigNoz role through the
    #                     same access paths the policy layer authorized
    def access_resource
      raise NotImplementedError
    end
  end
end
