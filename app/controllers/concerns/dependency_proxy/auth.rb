# frozen_string_literal: true

module DependencyProxy
  module Auth
    extend ActiveSupport::Concern

    included do
      # We disable `authenticate_user!` since the `DependencyProxy::Auth` performs auth using JWT token
      skip_before_action :authenticate_user!, raise: false
      prepend_before_action :authenticate_user_from_jwt_token!
    end

    def authenticate_user_from_jwt_token!
      return unless dependency_proxy_for_private_groups?

      authenticate_with_http_token do |token, _|
        user = user_from_token(token)
        sign_in(user) if user
      end

      request_bearer_token! unless current_user
    end

    private

    def dependency_proxy_for_private_groups?
      Feature.enabled?(:dependency_proxy_for_private_groups, default_enabled: true)
    end

    def request_bearer_token!
      # unfortunately, we cannot use https://api.rubyonrails.org/classes/ActionController/HttpAuthentication/Token.html#method-i-authentication_request
      response.headers['WWW-Authenticate'] = ::DependencyProxy::Registry.authenticate_header
      render plain: '', status: :unauthorized
    end

    def user_from_token(token)
      token_payload = DependencyProxy::AuthTokenService.decoded_token_payload(token)
      User.find(token_payload['user_id'])
    rescue JWT::DecodeError, JWT::ExpiredSignature, JWT::ImmatureSignature
      nil
    end
  end
end
