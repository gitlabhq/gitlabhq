# frozen_string_literal: true

module Import
  module BitbucketImport
    class TokenRefreshStrategy
      include Gitlab::ExclusiveLeaseHelpers
      include Gitlab::BitbucketImport::Loggable

      LOCK_TTL = 60.seconds
      LOCK_RETRIES = 30
      LOCK_SLEEP = 1.second

      def initialize(project)
        @project = project
      end

      def refresh(connection)
        in_lock(lock_key, ttl: LOCK_TTL, retries: LOCK_RETRIES, sleep_sec: LOCK_SLEEP) do
          adopt_persisted(connection)
          connection.perform_refresh! if connection.expired?
          persist(connection)
        end
      end

      private

      attr_reader :project

      def lock_key
        "bitbucket-import:refresh:#{project.id}"
      end

      def adopt_persisted(connection)
        credentials = project.import_data.reset.credentials

        if credentials.blank?
          log_warn(message: 'Bitbucket OAuth credentials missing on import_data; refreshing with in-memory token')
          return
        end

        return if credentials[:refresh_token] == connection.refresh_token &&
          credentials[:token] == connection.token

        connection.adopt_credentials(
          token: credentials[:token],
          expires_at: credentials[:expires_at],
          expires_in: credentials[:expires_in],
          refresh_token: credentials[:refresh_token]
        )
      end

      def persist(connection)
        import_data = project.import_data
        credentials = import_data.credentials.to_h

        return if credentials.blank?

        return if credentials[:token] == connection.token &&
          credentials[:refresh_token] == connection.refresh_token

        import_data.update!(
          credentials: credentials.merge(
            token: connection.token,
            expires_at: connection.expires_at,
            expires_in: connection.expires_in,
            refresh_token: connection.refresh_token,
            password: connection.token
          )
        )
      end
    end
  end
end
