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
      include Gitlab::Utils::StrongMemoize

      def find_current_user!
        user = find_user_from_access_token || find_user_from_warden
        return unless user

        forbidden!('User is blocked') unless Gitlab::UserAccess.new(user).allowed? && user.can?(:access_api)

        user
      end

      def access_token
        strong_memoize(:access_token) do
          find_oauth_access_token || find_personal_access_token
        end
      end

      def validate_access_token!(scopes: [])
        return unless access_token

        case AccessTokenValidationService.new(access_token, request: request).validate(scopes: scopes)
        when AccessTokenValidationService::INSUFFICIENT_SCOPE
          raise InsufficientScopeError.new(scopes)
        when AccessTokenValidationService::EXPIRED
          raise ExpiredError
        when AccessTokenValidationService::REVOKED
          raise RevokedError
        end
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
    end

    module ClassMethods
      private

      def install_error_responders(base)
        error_classes = [MissingTokenError, TokenNotFoundError,
                         ExpiredError, RevokedError, InsufficientScopeError]

        base.__send__(:rescue_from, *error_classes, oauth2_bearer_token_error_handler) # rubocop:disable GitlabSecurity/PublicSend
      end

      def oauth2_bearer_token_error_handler
        proc do |e|
          response =
            case e
            when MissingTokenError
              Rack::OAuth2::Server::Resource::Bearer::Unauthorized.new

            when TokenNotFoundError
              Rack::OAuth2::Server::Resource::Bearer::Unauthorized.new(
                :invalid_token,
                "Bad Access Token.")

            when ExpiredError
              Rack::OAuth2::Server::Resource::Bearer::Unauthorized.new(
                :invalid_token,
                "Token is expired. You can either do re-authorization or token refresh.")

            when RevokedError
              Rack::OAuth2::Server::Resource::Bearer::Unauthorized.new(
                :invalid_token,
                "Token was revoked. You have to re-authorize from the user.")

            when InsufficientScopeError
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

    #
    # Exceptions
    #

    AuthenticationException = Class.new(StandardError)
    MissingTokenError = Class.new(AuthenticationException)
    TokenNotFoundError = Class.new(AuthenticationException)
    ExpiredError = Class.new(AuthenticationException)
    RevokedError = Class.new(AuthenticationException)
    UnauthorizedError = Class.new(AuthenticationException)

    class InsufficientScopeError < AuthenticationException
      attr_reader :scopes
      def initialize(scopes)
        @scopes = scopes.map { |s| s.try(:name) || s }
      end
    end
  end
end
