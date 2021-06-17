# frozen_string_literal: true

module Gitlab
  class LfsToken
    module LfsTokenHelper
      def user?
        actor.is_a?(User)
      end

      def actor_name
        user? ? actor.username : "lfs+deploy-key-#{actor.id}"
      end
    end

    include LfsTokenHelper

    DEFAULT_EXPIRE_TIME = 7200 # Default value 2 hours

    attr_accessor :actor

    def initialize(actor)
      @actor =
        case actor
        when DeployKey, User
          actor
        when Key
          actor.user
        else
          raise 'Bad Actor'
        end
    end

    def token
      HMACToken.new(actor).token(DEFAULT_EXPIRE_TIME)
    end

    # When the token is an lfs one and the actor
    # is blocked or the password has been changed,
    # the token is no longer valid
    def token_valid?(token_to_check)
      HMACToken.new(actor).token_valid?(token_to_check) && valid_user?
    end

    def deploy_key_pushable?(project)
      actor.is_a?(DeployKey) && actor.can_push_to?(project)
    end

    def type
      user? ? :lfs_token : :lfs_deploy_token
    end

    def valid_user?
      return true unless user?

      !actor.blocked? && !actor.password_expired_if_applicable?
    end

    def authentication_payload(repository_http_path)
      {
        username: actor_name,
        lfs_token: token,
        repository_http_path: repository_http_path,
        expires_in: DEFAULT_EXPIRE_TIME
      }
    end

    def basic_encoding
      ActionController::HttpAuthentication::Basic.encode_credentials(actor_name, token)
    end

    private # rubocop:disable Lint/UselessAccessModifier

    class HMACToken
      include LfsTokenHelper

      def initialize(actor)
        @actor = actor
      end

      def token(expire_time)
        hmac_token = JSONWebToken::HMACToken.new(secret)
        hmac_token.expire_time = Time.now + expire_time
        hmac_token[:data] = { actor: actor_name }
        hmac_token.encoded
      end

      def token_valid?(token_to_check)
        decoded_token = JSONWebToken::HMACToken.decode(token_to_check, secret).first
        decoded_token.dig('data', 'actor') == actor_name
      rescue JWT::DecodeError
        false
      end

      private

      attr_reader :actor

      def secret
        salt + key
      end

      def salt
        case actor
        when DeployKey, Key
          actor.fingerprint.delete(':').first(16)
        when User
          # Take the last 16 characters as they're more unique than the first 16
          actor.id.to_s + actor.encrypted_password.last(16)
        end
      end

      def key
        # Take 16 characters of attr_encrypted_db_key_base, as that's what the
        # cipher needs exactly
        Settings.attr_encrypted_db_key_base.first(16)
      end
    end
  end
end
