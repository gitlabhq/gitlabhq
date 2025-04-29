# frozen_string_literal: true

require 'omniauth/strategies/saml'

module OmniAuth
  module Strategies
    class SAML
      # Store the original method
      alias_method :original_callback_url, :callback_url

      # NOTE: This method duplicates code from omniauth-saml
      #       so that we can access authn_request to store it
      #       See: https://github.com/omniauth/omniauth-saml/issues/172
      def request_phase
        authn_request = OneLogin::RubySaml::Authrequest.new

        store_authn_request_id(authn_request)

        with_settings do |settings|
          redirect(authn_request.create(settings, additional_params_for_authn_request))
        end
      end

      # NOTE: Overriding the callback_url method since in certain cases
      #       IDP doesn't return the correct ACS URL for us to validate
      #       See: https://gitlab.com/gitlab-org/gitlab/-/issues/491634
      def callback_url
        full_host + callback_path
      end

      private

      def store_authn_request_id(authn_request)
        Gitlab::Auth::Saml::OriginValidator.new(session).store_origin(authn_request)
      end
    end
  end
end
