# frozen_string_literal: true

module AuditEvents
  module GoogleCloud
    class Authentication
      def initialize(scope:)
        @scope = scope
      end

      def generate_access_token(client_email, private_key)
        credentials = Google::Auth::ServiceAccountCredentials.make_creds(
          json_key_io: StringIO.new({ client_email: client_email, private_key: private_key }.to_json),
          scope: @scope
        )
        credentials.fetch_access_token!["access_token"]
      rescue StandardError => e
        ::Gitlab::ErrorTracking.track_exception(e, client_email: client_email)
        nil
      end
    end
  end
end
