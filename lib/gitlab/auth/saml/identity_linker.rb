# frozen_string_literal: true

module Gitlab
  module Auth
    module Saml
      class IdentityLinker < OmniauthIdentityLinkerBase
        extend ::Gitlab::Utils::Override

        UnverifiedRequest = Class.new(StandardError)

        override :link
        def link
          raise_unless_request_is_gitlab_initiated! if unlinked?

          super
        end

        protected

        def raise_unless_request_is_gitlab_initiated!
          raise UnverifiedRequest unless valid_gitlab_initiated_request?
        end

        def valid_gitlab_initiated_request?
          OriginValidator.new(session).gitlab_initiated?(saml_response)
        end

        def saml_response
          oauth.fetch(:extra, {}).fetch(:response_object, {})
        end
      end
    end
  end
end

Gitlab::Auth::Saml::IdentityLinker.prepend_mod
