# frozen_string_literal: true

# The Conan client uses a JWT for authenticating with remotes.
# This class encodes and decodes a user's personal access token or
# CI_JOB_TOKEN into a JWT that is used by the Conan client to
# authenticate with GitLab

module Gitlab
  class ConanToken
    HMAC_KEY = 'gitlab-conan-packages'
    CONAN_TOKEN_EXPIRE_TIME = 1.day.freeze

    attr_reader :access_token_id, :user_id

    class << self
      def from_personal_access_token(access_token)
        new(access_token_id: access_token.id, user_id: access_token.user_id)
      end

      def from_job(job)
        new(access_token_id: job.token, user_id: job.user.id)
      end

      def from_deploy_token(deploy_token)
        new(access_token_id: deploy_token.token, user_id: deploy_token.username)
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

    def initialize(access_token_id:, user_id:)
      @access_token_id = access_token_id
      @user_id = user_id
    end

    def to_jwt
      hmac_token.encoded
    end

    private

    def hmac_token
      JSONWebToken::HMACToken.new(self.class.secret).tap do |token|
        token['access_token'] = access_token_id
        token['user_id'] = user_id
        token.expire_time = token.issued_at + CONAN_TOKEN_EXPIRE_TIME
      end
    end
  end
end
