# frozen_string_literal: true

# The Conan client uses a JWT for authenticating with remotes.
# This class encodes and decodes a user's personal access token or
# CI_JOB_TOKEN into a JWT that is used by the Conan client to
# authenticate with GitLab

module Gitlab
  class ConanToken
    HMAC_KEY = 'gitlab-conan-packages'
    MAX_CONAN_TOKEN_EXPIRE_TIME = 3.months.freeze

    attr_reader :access_token_id, :user_id, :expire_at

    class << self
      def from_personal_access_token(token_id, personal_token)
        return unless personal_token&.active?

        new(access_token_id: token_id, user_id: personal_token.user_id,
          expire_at: personal_token.expires_at&.at_beginning_of_day)
      end

      def from_job(job)
        return unless job&.running?

        new(access_token_id: job.token, user_id: job.user.id, expire_at: job.project.build_timeout.seconds.from_now)
      end

      def from_deploy_token(deploy_token)
        new(access_token_id: deploy_token.token, user_id: deploy_token.username, expire_at: deploy_token.expires_at)
      end

      def decode(jwt)
        payload = JSONWebToken::HMACToken.decode(jwt, secret).first
        new(access_token_id: payload['access_token'], user_id: payload['user_id'])
      rescue JWT::DecodeError, JWT::ExpiredSignature, JWT::ImmatureSignature
        # we return on expired and errored tokens because the Conan client
        # will request a new token automatically.
      end

      def secret
        OpenSSL::HMAC.hexdigest(
          OpenSSL::Digest.new('SHA256'),
          ::Settings.attr_encrypted_db_key_base,
          HMAC_KEY
        )
      end
    end

    def initialize(access_token_id:, user_id:, expire_at: nil)
      @access_token_id = access_token_id
      @user_id = user_id
      @expire_at = [expire_at, MAX_CONAN_TOKEN_EXPIRE_TIME.from_now].select(&:present?).min
    end

    def to_jwt
      hmac_token.encoded
    end

    private

    def hmac_token
      JSONWebToken::HMACToken.new(self.class.secret).tap do |token|
        token['access_token'] = access_token_id
        token['user_id'] = user_id
        token.expire_time = expire_at
      end
    end
  end
end
