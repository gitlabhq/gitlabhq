# frozen_string_literal: true

module Groups
  module Observability
    # Mints a per-user SigNoz session via the backend-for-frontend (BFF) broker.
    #
    # The browser never performs an OAuth redirect: GitLab brokers the GitLab
    # OIDC -> SigNoz exchange server-to-server and returns per-user tokens, which
    # app.vue injects into the embedded iframe over the existing O11Y_JWT_LOGIN
    # postMessage channel.
    class SessionsController < Groups::ApplicationController
      include ::Observability::SessionActions

      private

      def ensure_bff_enabled!
        render_404 unless ::Feature.enabled?(:observability_per_user_bff_auth, group)
      end

      def observability_setting
        group.observability_group_o11y_setting
      end
      strong_memoize_attr :observability_setting

      def authorize_read_observability!
        return render_404 unless ::Feature.enabled?(:observability_sass_features, group)

        render_404 unless Ability.allowed?(current_user, :read_observability_portal, group)
      end

      def access_resource
        group
      end
    end
  end
end
