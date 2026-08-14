# frozen_string_literal: true

module Authn
  # Provider-agnostic registry for sign-in flows that redirect the login page
  # into an OmniAuth provider.
  #
  # This is the single place that knows which integrations opt into the
  # auto-submitting `redirect_to_provider` sign-in page. It also acts as an
  # allowlist so `redirect_to_provider` cannot be used with an arbitrary
  # user-supplied provider string (e.g. `ldapmain`, `database`) that was never
  # designed for this flow.
  #
  # Each registered redirector must expose:
  #   - PROVIDER (String)             the OmniAuth provider name
  #   - TARGET_FLOW (String)          the target_flow query value it handles
  #   - .enabled?                     whether the flow is currently active
  #   - .trusted_request?(request)    whether the request is a trusted origin
  module ProviderSignInRedirect
    SESSION_KEY = :provider_sign_in_redirect

    REDIRECTORS = [
      Authn::ChatGpt::SiwcRedirect
    ].freeze

    def self.enabled?(provider)
      redirector_for_provider(provider)&.enabled? || false
    end

    def self.provider_for_target_flow(target_flow, request)
      redirector = REDIRECTORS.find { |r| r::TARGET_FLOW == target_flow }
      return unless redirector&.enabled?
      return unless redirector.trusted_request?(request)

      redirector::PROVIDER
    end

    def self.redirector_for_provider(provider)
      REDIRECTORS.find { |r| r::PROVIDER == provider }
    end
  end
end
