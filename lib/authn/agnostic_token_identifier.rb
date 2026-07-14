# frozen_string_literal:true

module Authn
  class AgnosticTokenIdentifier
    NotFoundError = Class.new(StandardError)
    TOKEN_TYPES = [
      ::Authn::Tokens::DeployToken,
      ::Authn::Tokens::FeedToken,
      ::Authn::Tokens::PersonalAccessToken,
      ::Authn::Tokens::OauthApplicationSecret,
      ::Authn::Tokens::ClusterAgentToken,
      ::Authn::Tokens::RunnerAuthenticationToken,
      ::Authn::Tokens::RunnerRegistrationToken,
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
      token_types.find { |x| x.prefix?(plaintext) }
    end

    def self.token_types
      TOKEN_TYPES
    end
  end
end

Authn::AgnosticTokenIdentifier.prepend_mod_with('Authn::AgnosticTokenIdentifier')
