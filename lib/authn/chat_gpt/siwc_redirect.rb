# frozen_string_literal: true

module Authn
  module ChatGpt
    # Owns everything specific to the "Sign in with ChatGPT" (SIWC) connector
    # installation flow. Registered in Authn::ProviderSignInRedirect so that
    # neither SessionsController nor OauthResourceOwnerRedirectResolver need to
    # reference ChatGPT directly.
    class SiwcRedirect
      PROVIDER = 'chatgpt'
      TARGET_FLOW = 'chatgpt_siwc'
      REDIRECT_URI_HOST = 'chatgpt.com'

      def self.enabled?
        Feature.enabled?(:chatgpt_siwc_login_redirect, :instance) &&
          ::Gitlab::Auth::OAuth::Provider.enabled?(PROVIDER)
      end

      def self.trusted_request?(request)
        client_id = request.query_parameters['client_id']
        return false if client_id.blank?

        application = ::Authn::OauthApplication.by_uid(client_id)
        return false unless application
        return false unless application.owner_id.nil? && application.owner_type.nil?
        return false if application.dynamic

        requested_redirect_uri_valid?(request, application)
      end

      def self.requested_redirect_uri_valid?(request, application)
        requested_redirect_uri = request.query_parameters['redirect_uri']
        return false if requested_redirect_uri.blank?
        return false unless redirect_uri_host_allowed?(requested_redirect_uri)

        ::Doorkeeper::OAuth::Helpers::URIChecker
          .valid_for_authorization?(requested_redirect_uri, application.redirect_uri)
      end
      private_class_method :requested_redirect_uri_valid?

      def self.redirect_uri_host_allowed?(requested_redirect_uri)
        URI.parse(requested_redirect_uri).host == REDIRECT_URI_HOST
      rescue URI::InvalidURIError
        false
      end
      private_class_method :redirect_uri_host_allowed?
    end
  end
end
