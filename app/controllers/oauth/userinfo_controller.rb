# frozen_string_literal: true

module Oauth
  class UserinfoController < Doorkeeper::OpenidConnect::UserinfoController
    include ::Gitlab::EndpointAttributes
    include Gitlab::Utils::StrongMemoize

    feature_category :system_access

    private

    # Overrides Doorkeeper::Rails::Helpers#doorkeeper_token to accept
    # IAM-issued JWTs before falling back to the Doorkeeper database lookup.
    # Memoizes nil like the base method, so an invalid token is validated
    # once per request rather than once per doorkeeper_token call.
    # https://github.com/doorkeeper-gem/doorkeeper/blob/v5.9.1/lib/doorkeeper/rails/helpers.rb#L72-L79
    def doorkeeper_token
      iam_oauth_token || super
    end
    strong_memoize_attr :doorkeeper_token

    def iam_oauth_token
      raw_token = Doorkeeper::OAuth::Token.from_request(
        request, *Doorkeeper.config.access_token_methods
      )

      return unless raw_token

      ::Authn::Tokens::IamOauthToken.from_jwt(raw_token)
    end
  end
end
