# frozen_string_literal: true

module Authn
  module Tokens
    module Concerns
      # Shared Doorkeeper::AccessToken duck-type surface for stateless (no DB
      # row) token classes, used by AccessTokenValidationService and the OIDC
      # ClaimsBuilder. Including classes must define #expires_at, #revoked?,
      # #user, #user_id, and #raw_scopes.
      module DoorkeeperCompatible
        extend ActiveSupport::Concern

        def active?
          !expired? && !revoked?
        end

        def expired?
          expires_at.present? && expires_at.past?
        end

        # For compatibility with Doorkeeper which mirrors Doorkeeper::AccessToken#accessible?
        # https://github.com/doorkeeper-gem/doorkeeper/blob/v5.8.1/lib/doorkeeper/models/concerns/accessible.rb#L10
        def accessible?
          active? && user.active?
        end

        # Called by doorkeeper_authorize! to check required endpoint scopes, mirrors Doorkeeper::AccessToken#acceptable?
        # https://github.com/doorkeeper-gem/doorkeeper/blob/v5.8.1/lib/doorkeeper/models/concerns/accessible.rb#L14
        def acceptable?(required_scopes)
          accessible? && includes_scope?(*required_scopes)
        end

        def includes_scope?(*required_scopes)
          required_scopes.blank? || required_scopes.any? { |scope| scopes.include?(scope.to_s) }
        end

        # Doorkeeper::AccessToken#scopes returns a Doorkeeper::OAuth::Scopes
        # object and the OIDC ClaimsBuilder calls scopes.exists?, so mirror
        # that here instead of exposing the raw Array.
        def scopes
          Doorkeeper::OAuth::Scopes.from_array(raw_scopes)
        end

        # For compatibility with AccessTokenValidationService.
        def resource_owner_id
          user_id
        end

        # Neither token type has a backing Doorkeeper application record.
        def application
          nil
        end
      end
    end
  end
end
