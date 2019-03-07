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

    DEFAULT_EXPIRE_TIME = 1800

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

    def token_valid?(token_to_check)
      HMACToken.new(actor).token_valid?(token_to_check) ||
        LegacyRedisDeviseToken.new(actor).token_valid?(token_to_check)
    end

    def deploy_key_pushable?(project)
      actor.is_a?(DeployKey) && actor.can_push_to?(project)
    end

    def type
      user? ? :lfs_token : :lfs_deploy_token
    end

    def authentication_payload(repository_http_path)
      {
        username: actor_name,
        lfs_token: token,
        repository_http_path: repository_http_path,
        expires_in: DEFAULT_EXPIRE_TIME
      }
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

    # TODO: LegacyRedisDeviseToken and references need to be removed after
    # next released milestone
    #
    class LegacyRedisDeviseToken
      TOKEN_LENGTH = 50
      DEFAULT_EXPIRY_TIME = 1800 * 1000 # 30 mins

      def initialize(actor)
        @actor = actor
      end

      def token_valid?(token_to_check)
        Devise.secure_compare(stored_token, token_to_check)
      end

      def stored_token
        Gitlab::Redis::SharedState.with { |redis| redis.get(state_key) }
      end

      # This method exists purely to facilitate legacy testing to ensure the
      # same redis key is used.
      #
      def store_new_token(expiry_time_in_ms = DEFAULT_EXPIRY_TIME)
        Gitlab::Redis::SharedState.with do |redis|
          new_token = Devise.friendly_token(TOKEN_LENGTH)
          redis.set(state_key, new_token, px: expiry_time_in_ms)
          new_token
        end
      end

      private

      attr_reader :actor

      def state_key
        "gitlab:lfs_token:#{actor.class.name.underscore}_#{actor.id}"
      end
    end
  end
end
