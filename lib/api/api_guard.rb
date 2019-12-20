# frozen_string_literal: true

# Guard API with OAuth 2.0 Access Token

require 'rack/oauth2'

module API
  module APIGuard
    extend ActiveSupport::Concern

    included do |base|
      # OAuth2 Resource Server Authentication
      use Rack::OAuth2::Server::Resource::Bearer, 'The API' do |request|
        # The authenticator only fetches the raw token string

        # Must yield access token to store it in the env
        request.access_token
      end

      use AdminModeMiddleware

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
      prepend_if_ee('EE::API::APIGuard::HelperMethods') # rubocop: disable Cop/InjectEnterpriseEditionModule
      include Gitlab::Auth::AuthFinders

      def find_current_user!
        user = find_user_from_sources
        return unless user

        unless api_access_allowed?(user)
          forbidden!(api_access_denied_message(user))
        end

        # Set admin mode for API requests (if admin)
        if Feature.enabled?(:user_mode_in_session)
          current_user_mode = Gitlab::Auth::CurrentUserMode.new(user)

          current_user_mode.enable_sessionless_admin_mode!
        end

        user
      end

      def find_user_from_sources
        find_user_from_access_token ||
          find_user_from_job_token ||
          find_user_from_warden
      end

      private

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
        Gitlab::UserAccess.new(user).allowed? && user.can?(:access_api)
      end

      def api_access_denied_message(user)
        Gitlab::Auth::UserAccessDeniedReason.new(user).rejection_message
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
                         Gitlab::Auth::InsufficientScopeError]

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
            end

          response.finish
        end
      end
    end

    class AdminModeMiddleware < ::Grape::Middleware::Base
      def initialize(app, **options)
        super
      end

      def call(env)
        if Feature.enabled?(:user_mode_in_session)
          session = {}
          Gitlab::Session.with_session(session) do
            app.call(env)
          end
        else
          app.call(env)
        end
      end
    end
  end
end
