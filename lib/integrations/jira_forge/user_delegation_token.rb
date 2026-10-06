# frozen_string_literal: true

module Integrations
  module JiraForge
    # A short-lived GitLab-signed delegation token binding the signed-in GitLab
    # user to app-context (invokeRemote) calls from the GitLab for Jira (Forge)
    # app.
    #
    # Forge attaches the FIT and app system token only to app-context calls, and
    # never exposes the user's managed OAuth token to app code -- so the
    # first-link subscribe call (app-context, FIT-authenticated) cannot carry
    # the user's OAuth token. Instead the app mints this token at config-page
    # sign-in (a user-context call) and presents it on the link call, letting
    # GitLab verify the user's namespace permission itself.
    #
    # The token is scoped to the Jira account + site it was minted for: the
    # account_id/cloud_id claims are asserted by the app at mint time (the
    # honest-app-at-mint trust anchor) and MUST match the FIT of the call that
    # presents it. That turns a leaked token from an ambient bearer credential
    # into a delegation usable only from that user's own Jira account and site.
    #
    # Signing modelled on Gitlab::ConanToken.
    class UserDelegationToken
      HMAC_KEY = 'gitlab-jira-forge-user-delegation'
      EXPIRE_TIME = 2.hours

      attr_reader :user_id, :account_id, :cloud_id

      class << self
        def build(user:, account_id:, cloud_id:)
          new(user_id: user.id, account_id: account_id, cloud_id: cloud_id)
        end

        # nil on a tampered or expired token (JWT::ExpiredSignature is a
        # JWT::DecodeError).
        def decode(jwt)
          payload = JSONWebToken::HMACToken.decode(jwt, secret).first

          new(
            user_id: payload['user_id'],
            account_id: payload['account_id'],
            cloud_id: payload['cloud_id']
          )
        rescue JWT::DecodeError
          nil
        end

        def secret
          OpenSSL::HMAC.hexdigest(
            OpenSSL::Digest.new('SHA256'),
            ::Gitlab::Encryption::KeyProvider[:db_key_base].encryption_key.secret,
            HMAC_KEY
          )
        end
      end

      def initialize(user_id:, account_id:, cloud_id:)
        @user_id = user_id
        @account_id = account_id
        @cloud_id = cloud_id
      end

      # Whether the token was minted for the Jira account + site of the given
      # verified FIT.
      def matches_fit?(fit)
        account_id.present? && cloud_id.present? &&
          account_id == fit.principal && cloud_id == fit.cloud_id
      end

      def to_jwt
        JSONWebToken::HMACToken.new(self.class.secret).tap do |token|
          token['user_id'] = user_id
          token['account_id'] = account_id
          token['cloud_id'] = cloud_id
          token.expire_time = EXPIRE_TIME.from_now
        end.encoded
      end
    end
  end
end
