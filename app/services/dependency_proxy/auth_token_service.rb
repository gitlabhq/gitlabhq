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

    # TODO: Rename to make it obvious how it's used in Gitlab::Auth::RequestAuthenticator
    # which is to return an <object>.<id> that is used as a rack-attack discriminator
    # that way it cannot be confused with `.user_or_token_from_jwt`
    # https://gitlab.com/gitlab-org/gitlab/-/issues/454518
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

    def self.user_or_token_from_jwt(raw_jwt)
      token_payload = self.new(raw_jwt).execute

      if token_payload['personal_access_token']
        get_personal_access_token(token_payload['personal_access_token'])
      elsif token_payload['group_access_token']
        # a group access token is a personal access token in disguise
        get_personal_access_token(token_payload['group_access_token'])
      elsif token_payload['user_id']
        get_user(token_payload['user_id'])
      elsif token_payload['deploy_token']
        get_deploy_token(token_payload['deploy_token'])
      end
    rescue JWT::DecodeError, JWT::ExpiredSignature, JWT::ImmatureSignature
      nil
    end

    def self.get_user(user_id)
      User.find(user_id)
    end

    def self.get_personal_access_token(raw_token)
      PersonalAccessTokensFinder.new(state: 'active').find_by_token(raw_token)
    end

    def self.get_deploy_token(raw_token)
      DeployToken.active.find_by_token(raw_token)
    end
  end
end
