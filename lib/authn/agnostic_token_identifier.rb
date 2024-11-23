# frozen_string_literal:true

module Authn
  class AgnosticTokenIdentifier
    NotFoundError = Class.new(StandardError)
    UnsupportedTokenError = Class.new(StandardError)
    TOKEN_TYPES = [
      ::Authn::Tokens::DeployToken,
      ::Authn::Tokens::FeedToken,
      ::Authn::Tokens::PersonalAccessToken,
      ::Authn::Tokens::OauthApplicationSecret
    ].freeze

    def self.token_for(plaintext, source)
      TOKEN_TYPES.find { |x| x.prefix?(plaintext) }&.new(plaintext, source)
    end
  end
end
