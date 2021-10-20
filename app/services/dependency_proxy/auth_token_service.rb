# frozen_string_literal: true

module DependencyProxy
  class AuthTokenService < DependencyProxy::BaseService
    attr_reader :token

    def initialize(token)
      @token = token
    end

    def execute
      JSONWebToken::HMACToken.decode(token, ::Auth::DependencyProxyAuthenticationService.secret).first
    end

    def self.user_or_deploy_token_from_jwt(raw_jwt)
      token_payload = self.new(raw_jwt).execute

      if token_payload['user_id']
        User.find(token_payload['user_id'])
      elsif token_payload['deploy_token']
        DeployToken.active.find_by_token(token_payload['deploy_token'])
      end
    rescue JWT::DecodeError, JWT::ExpiredSignature, JWT::ImmatureSignature
      nil
    end
  end
end
