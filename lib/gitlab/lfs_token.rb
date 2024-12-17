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

      def container_gid
        container ? container.to_gid.to_s : nil
      end
    end

    include LfsTokenHelper

    DEFAULT_EXPIRE_TIME = 7200 # Default value 2 hours

    attr_accessor :actor

    def initialize(actor, container)
      @actor =
        case actor
        when DeployKey, User
          actor
        when Key
          actor.user
        else
          raise 'Bad Actor'
        end

      @container = container
    end

    def token
      HMACToken.new(actor, container).token(DEFAULT_EXPIRE_TIME)
    end

    # When the token is an lfs one and the actor
    # is blocked or the password has been changed,
    # the token is no longer valid
    def token_valid?(token_to_check)
      HMACToken.new(actor, container).token_valid?(token_to_check) && valid_user?
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

    private

    attr_reader :container

    class HMACToken
      include LfsTokenHelper

      def initialize(actor, container)
        @actor = actor
        @container = container
      end

      def token(expire_time)
        hmac_token = JSONWebToken::HMACToken.new(secret)
        hmac_token.expire_time = Time.now + expire_time
        hmac_token[:data] = { actor: actor_name }
        hmac_token[:data][:container_gid] = container_gid if container

        hmac_token.encoded
      end

      def token_valid?(token_to_check)
        decoded_token = JSONWebToken::HMACToken.decode(token_to_check, secret).first
        return false if decoded_token.dig('data', 'actor') != actor_name

        token_container = decoded_token.dig('data', 'container_gid')
        return true if token_container.blank? || container.blank?

        token_container == container_gid
      rescue JWT::DecodeError
        false
      end

      private

      attr_reader :actor, :container

      def secret
        case actor
        when DeployKey, Key
          # Since fingerprint is based on the public key, let's take more bytes from attr_encrypted_db_key_base
          actor.fingerprint_sha256.first(16) + Settings.attr_encrypted_db_key_base_32
        when User
          # Take the last 16 characters as they're more unique than the first 16
          actor.id.to_s + actor.encrypted_password.last(16) + Settings.attr_encrypted_db_key_base.first(16)
        end
      end
    end
  end
end
