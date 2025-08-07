# frozen_string_literal: true

# Security patch for Doorkeeper DeviceAuthorizationGrant
# Fixes privilege escalation vulnerability in scope validation
# This patch prevents applications from escalating privileges through device authorization
# Could be removed if upstream fix is provided
# https://gitlab.com/gitlab-org/gitlab/-/issues/543138

if defined?(Doorkeeper::DeviceAuthorizationGrant::OAuth::DeviceAuthorizationRequest)
  Doorkeeper::DeviceAuthorizationGrant::OAuth::DeviceAuthorizationRequest.class_eval do
    validate :scopes_match_configured, error: Doorkeeper::Errors::InvalidScope

    private

    def validate_scopes_match_configured
      return false if scopes.blank?

      Doorkeeper::OAuth::Helpers::ScopeChecker.valid?(
        scope_str: scopes.to_s,
        server_scopes: server.scopes,
        app_scopes: client.scopes,
        grant_type: Doorkeeper::DeviceAuthorizationGrant::OAuth::DEVICE_CODE
      )
    end
  end
end
