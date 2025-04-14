# frozen_string_literal:true

module Authn
  class AgnosticTokenIdentifier
    NotFoundError = Class.new(StandardError)
    UnsupportedTokenError = Class.new(StandardError)
    TOKEN_TYPES = [
      ::Authn::Tokens::DeployToken,
      ::Authn::Tokens::FeedToken,
      ::Authn::Tokens::PersonalAccessToken,
      ::Authn::Tokens::OauthApplicationSecret,
      ::Authn::Tokens::ClusterAgentToken,
      ::Authn::Tokens::RunnerAuthenticationToken,
      ::Authn::Tokens::CiTriggerToken,
      ::Authn::Tokens::CiJobToken,
      ::Authn::Tokens::FeatureFlagsClientToken,
      ::Authn::Tokens::GitlabSession,
      ::Authn::Tokens::IncomingEmailToken
    ].freeze

    def self.token_for(plaintext, source)
      token_type(plaintext)&.new(plaintext, source)
    end

    def self.token?(plaintext)
      token_type(plaintext).present?
    end

    def self.token_type(plaintext)
      TOKEN_TYPES.find { |x| x.prefix?(plaintext) }
    end
  end
end
