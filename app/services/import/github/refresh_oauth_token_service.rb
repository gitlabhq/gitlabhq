# frozen_string_literal: true

module Import
  module Github
    # Refreshes an expiring GitHub OAuth access token stored in a project's import data.
    class RefreshOauthTokenService
      include ::Gitlab::ExclusiveLeaseHelpers

      class BadRefreshTokenError < ::Octokit::Unauthorized
        private

        def build_error_message
          'GitHub refresh token is invalid or expired. Authorize GitHub again.'
        end
      end

      EXPIRY_MARGIN = 5.minutes
      LEASE_TTL = 1.minute
      LEASE_RETRIES = 25
      LEASE_SLEEP = 0.2
      TRANSIENT_ERRORS = [FailedToObtainLockError, ::OAuth2::Error, ::Faraday::Error].freeze

      def initialize(project)
        @project = project
      end

      def refreshable?
        credentials[:refresh_token].present?
      end

      # Returns the stored access token, refreshing it first if it is about to expire. If the
      # refresh fails for a temporary reason, returns the stored token while it is still valid.
      #
      # @return [String, nil]
      def current_token
        token = credentials.fetch(:user, nil)
        return token unless refreshable? && expiring?

        execute(token)
      rescue *TRANSIENT_ERRORS
        raise if expired?

        token
      end

      # Refreshes the token the caller used. If another job already refreshed it, returns the
      # stored token without calling GitHub.
      #
      # @param used_token [String] the access token the caller used
      # @raise [BadRefreshTokenError] if the user must authorize GitHub again
      # @return [String] the new access token
      def execute(used_token)
        in_lock(lease_key, ttl: LEASE_TTL, retries: LEASE_RETRIES, sleep_sec: LEASE_SLEEP) do
          import_data = project.import_data&.reload
          stored = import_data&.credentials || {}
          raise BadRefreshTokenError if stored[:refresh_token].blank?

          next stored[:user] if stored[:user] != used_token

          new_token = refresh(stored)
          import_data.merge_credentials(
            user: new_token.token,
            **::Gitlab::GithubImport::OauthClient.refresh_credentials(new_token)
          )
          import_data.save!

          new_token.token
        end
      end

      private

      attr_reader :project

      def credentials
        project.import_data&.credentials || {}
      end

      def expiring?
        expires_by?(EXPIRY_MARGIN.from_now)
      end

      def expired?
        expires_by?(Time.current)
      end

      def expires_by?(time)
        expires_at = credentials[:expires_at]
        expires_at.present? && Time.zone.at(expires_at.to_i) <= time
      end

      def refresh(stored)
        client = ::Gitlab::GithubImport::OauthClient.build
        raise BadRefreshTokenError unless client

        ::OAuth2::AccessToken.new(client, stored[:user], refresh_token: stored[:refresh_token]).refresh
      rescue ::OAuth2::Error => e
        raise BadRefreshTokenError if bad_refresh_token?(e)

        raise
      end

      def bad_refresh_token?(error)
        error.code == 'bad_refresh_token' || error.message.include?('bad_refresh_token')
      end

      def lease_key
        "import:github:oauth_token_refresh:#{project.id}"
      end
    end
  end
end
