# frozen_string_literal: true

module Import
  module Github
    # Creates the short-lived JSON Web Token used to authenticate the GitHub App.
    class AppJwtService
      CLOCK_SKEW = 60.seconds
      LIFETIME = 9.minutes

      ConfigurationError = Class.new(StandardError)

      def initialize(configuration: Configuration.new, current_time: -> { Time.current })
        @configuration = configuration
        @current_time = current_time
      end

      # Returns an RS256 GitHub App JWT from one consistent credential snapshot.
      #
      # @return [String] short-lived signed App authentication token
      # @raise [ConfigurationError] when credentials are absent, unreadable, or invalid
      # @note A file-backed key is read once per call. Neither key bytes nor the
      #   generated token are persisted or included in the sanitized error.
      def execute
        app_id = configuration.app_id
        private_key = configuration.private_key
        raise ConfigurationError, 'GitHub App credentials are not configured' unless app_id && private_key

        issued_at = current_time.call
        payload = {
          iat: (issued_at - CLOCK_SKEW).to_i,
          exp: (issued_at + LIFETIME).to_i,
          iss: app_id
        }

        JWT.encode(payload, OpenSSL::PKey::RSA.new(private_key), 'RS256')
      rescue OpenSSL::PKey::PKeyError
        raise ConfigurationError, 'GitHub App private key is invalid'
      end

      private

      attr_reader :configuration, :current_time
    end
  end
end
