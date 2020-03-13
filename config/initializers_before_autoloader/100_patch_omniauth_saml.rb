# frozen_string_literal: true

require 'omniauth/strategies/saml'

module OmniAuth
  module Strategies
    class SAML
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

      private

      def store_authn_request_id(authn_request)
        Gitlab::Auth::Saml::OriginValidator.new(session).store_origin(authn_request)
      end
    end
  end
end
