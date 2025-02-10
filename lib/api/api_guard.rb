# frozen_string_literal: true

# Guard API with OAuth 2.0 Access Token

require 'rack/oauth2'

module API
  module APIGuard
    extend ActiveSupport::Concern
    include Gitlab::Utils::StrongMemoize

    included do |base|
      # OAuth2 Resource Server Authentication
      use Rack::OAuth2::Server::Resource::Bearer, 'The API' do |request|
        # The authenticator only fetches the raw token string

        # Must yield access token to store it in the env
        request.access_token
      end

      use AdminModeMiddleware
      use ResponseCoercerMiddleware

      helpers HelperMethods

      install_error_responders(base)
    end

    class_methods do
      # Set the authorization scope(s) allowed for an API endpoint.
      #
      # A call to this method maps the given scope(s) to the current API
      # endpoint class. If this method is called multiple times on the same class,
      # the scopes are all aggregated.
      def allow_access_with_scope(scopes, options = {})
        Array(scopes).each do |scope|
          allowed_scopes << Scope.new(scope, options)
        end
      end

      def allowed_scopes
        @scopes ||= []
      end
    end

    # Helper Methods for Grape Endpoint
    module HelperMethods
      include Gitlab::Auth::AuthFinders

      def access_token
        strong_memoize(:api_guard_access_token) do
          super || find_personal_access_token_from_http_basic_auth
        end
      end

      def find_current_user!
        user = find_user_from_sources
        return unless user

        Gitlab::Auth::CurrentUserMode.bypass_session!(user.id) if bypass_session_for_admin_mode?(user)

        unless api_access_allowed?(user)
          forbidden!(api_access_denied_message(user))
        end

        check_dpop!(user)

        user
      end

      def find_user_from_sources
        strong_memoize(:find_user_from_sources) do
          if try(:namespace_inheritable, :authentication)
            user_from_namespace_inheritable ||
              user_from_warden
          else
            deploy_token_from_request ||
              find_user_from_bearer_token ||
              find_user_from_job_token ||
              user_from_warden
          end
        end
      end

      private

      def bypass_session_for_admin_mode?(user)
        return false unless user.is_a?(User) && Gitlab::CurrentSettings.admin_mode

        Gitlab::Session.with_session(current_request.session) { Gitlab::Auth::CurrentUserMode.new(user).admin_mode? } ||
          Gitlab::Auth::RequestAuthenticator.new(current_request).valid_access_token?(scopes: [:admin_mode])
      end

      # An array of scopes that were registered (using `allow_access_with_scope`)
      # for the current endpoint class. It also returns scopes registered on
      # `API::API`, since these are meant to apply to all API routes.
      def scopes_registered_for_endpoint
        @scopes_registered_for_endpoint ||=
          begin
            endpoint_classes = [options[:for].presence, ::API::API].compact
            endpoint_classes.reduce([]) do |memo, endpoint|
              if endpoint.respond_to?(:allowed_scopes)
                memo.concat(endpoint.allowed_scopes)
              else
                memo
              end
            end
          end
      end

      def api_access_allowed?(user)
        user_allowed_or_deploy_token?(user) && user.can?(:access_api)
      end

      def api_access_denied_message(user)
        Gitlab::Auth::UserAccessDeniedReason.new(user).rejection_message
      end

      def check_dpop!(user)
        return unless Feature.enabled?(:dpop_authentication, user)
        return unless api_request? && user.is_a?(User)

        token = extract_personal_access_token
        return unless PersonalAccessToken.find_by_token(token.to_s) # The token is not PAT, exit early

        ::Auth::DpopAuthenticationService.new(current_user: user,
          personal_access_token_plaintext: token,
          request: current_request).execute
      end

      def user_allowed_or_deploy_token?(user)
        Gitlab::UserAccess.new(user).allowed? || user.is_a?(DeployToken)
      end

      def user_from_warden
        user = find_user_from_warden

        return unless user
        return if two_factor_required_but_not_setup?(user)

        user
      end

      def two_factor_required_but_not_setup?(user)
        verifier = Gitlab::Auth::TwoFactorAuthVerifier.new(user, request)

        if verifier.two_factor_authentication_required? && verifier.current_user_needs_to_setup_two_factor?
          verifier.two_factor_grace_period_expired?
        else
          false
        end
      end
    end

    class_methods do
      private

      def install_error_responders(base)
        error_classes = [Gitlab::Auth::MissingTokenError,
                         Gitlab::Auth::TokenNotFoundError,
                         Gitlab::Auth::ExpiredError,
                         Gitlab::Auth::RevokedError,
                         Gitlab::Auth::ImpersonationDisabled,
                         Gitlab::Auth::InsufficientScopeError,
                         Gitlab::Auth::DpopValidationError]

        base.__send__(:rescue_from, *error_classes, oauth2_bearer_token_error_handler) # rubocop:disable GitlabSecurity/PublicSend
      end

      def oauth2_bearer_token_error_handler
        proc do |e|
          response =
            case e
            when Gitlab::Auth::MissingTokenError
              Rack::OAuth2::Server::Resource::Bearer::Unauthorized.new

            when Gitlab::Auth::TokenNotFoundError
              Rack::OAuth2::Server::Resource::Bearer::Unauthorized.new(
                :invalid_token,
                "Bad Access Token.")

            when Gitlab::Auth::ExpiredError
              Rack::OAuth2::Server::Resource::Bearer::Unauthorized.new(
                :invalid_token,
                "Token is expired. You can either do re-authorization or token refresh.")

            when Gitlab::Auth::RevokedError
              Rack::OAuth2::Server::Resource::Bearer::Unauthorized.new(
                :invalid_token,
                "Token was revoked. You have to re-authorize from the user.")

            when Gitlab::Auth::ImpersonationDisabled
              Rack::OAuth2::Server::Resource::Bearer::Unauthorized.new(
                :invalid_token,
                "Token is an impersonation token but impersonation was disabled.")

            when Gitlab::Auth::InsufficientScopeError
              # FIXME: ForbiddenError (inherited from Bearer::Forbidden of Rack::Oauth2)
              # does not include WWW-Authenticate header, which breaks the standard.
              Rack::OAuth2::Server::Resource::Bearer::Forbidden.new(
                :insufficient_scope,
                Rack::OAuth2::Server::Resource::ErrorMethods::DEFAULT_DESCRIPTION[:insufficient_scope],
                { scope: e.scopes })

            when Gitlab::Auth::DpopValidationError
              Rack::OAuth2::Server::Resource::Bearer::Unauthorized.new(
                :dpop_error,
                e)
            end

          status, headers, body = response.finish

          # Grape expects a Rack::Response
          # (https://github.com/ruby-grape/grape/commit/c117bff7d22971675f4b34367d3a98bc31c8fc02),
          # so we need to recreate the response again even though
          # response.finish already does this.
          # (https://github.com/nov/rack-oauth2/blob/40c9a99fd80486ccb8de0e4869ae384547c0d703/lib/rack/oauth2/server/abstract/error.rb#L26).
          Rack::Response.new(body, status, headers)
        end
      end
    end

    # Prior to Rack v2.1.x, returning a body of [nil] or [201] worked
    # because the body was coerced to a string. However, this no longer
    # works in Rack v2.1.0+. The Rack spec
    # (https://github.com/rack/rack/blob/master/SPEC.rdoc#the-body-)
    # says:
    #
    # The Body must respond to `each` and must only yield String values
    #
    # Because it's easy to return the wrong body type, this middleware
    # will:
    #
    # 1. Inspect each element of the body if it is an Array.
    # 2. Coerce each value to a string if necessary.
    # 3. Flag a test and development error.
    class ResponseCoercerMiddleware < ::Grape::Middleware::Base
      def call(env)
        response = super(env)

        status = response[0]
        body = response[2]

        return response if Rack::Utils::STATUS_WITH_NO_ENTITY_BODY[status]
        return response unless body.is_a?(Array)

        body.map! do |part|
          if part.is_a?(String)
            part
          else
            err = ArgumentError.new("The response body should be a String, but it is of type #{part.class}")
            Gitlab::ErrorTracking.track_and_raise_for_dev_exception(err)
            part.to_s
          end
        end

        response
      end
    end

    class AdminModeMiddleware < ::Grape::Middleware::Base
      def after
        # Use a Grape middleware since the Grape `after` blocks might run
        # before we are finished rendering the `Grape::Entity` classes
        Gitlab::Auth::CurrentUserMode.reset_bypass_session! if Gitlab::CurrentSettings.admin_mode

        # Explicit nil is needed or the api call return value will be overwritten
        nil
      end
    end
  end
end

API::APIGuard::HelperMethods.prepend_mod
