# frozen_string_literal: true

module Gitlab
  module Auth
    module OAuth
      class OauthResourceOwnerRedirectResolver
        include ::Gitlab::Routing

        attr_reader :request, :session

        def initialize(request, session)
          @request = request
          @session = session
        end

        def resolve_redirect_url
          provider = ::Authn::ProviderSignInRedirect.provider_for_target_flow(
            request.query_parameters['target_flow'], request
          )

          if provider
            session[::Authn::ProviderSignInRedirect::SESSION_KEY] = provider
            return new_user_session_url
          end

          new_user_session_url
        end
      end
    end
  end
end

Gitlab::Auth::OAuth::OauthResourceOwnerRedirectResolver.prepend_mod
