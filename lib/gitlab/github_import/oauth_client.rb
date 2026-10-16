# frozen_string_literal: true

module Gitlab
  module GithubImport
    # Builds the OAuth2 client for the instance's GitHub OAuth app, and reads the refresh
    # details GitHub returns when the app has expiring tokens turned on.
    module OauthClient
      def self.config
        Gitlab::Auth::OAuth::Provider.config_for('github')
      end

      CONNECTION_OPTIONS = { request: { open_timeout: 5, timeout: 10 } }.freeze

      # Returns nil when the GitHub OAuth provider is not configured.
      def self.build(config = self.config)
        return unless config

        options = { connection_opts: CONNECTION_OPTIONS.deep_dup }
          .deep_merge(config.dig('args', 'client_options').to_h.deep_symbolize_keys)
          .merge(ssl: { verify: config['verify_ssl'] })

        ::OAuth2::Client.new(config.app_id, config.app_secret, options)
      end

      # Returns an empty hash when the token can't be refreshed.
      #
      # @param token [OAuth2::AccessToken]
      # @return [Hash] with :refresh_token, :expires_at and :refresh_token_expires_at
      def self.refresh_credentials(token)
        return {} if token.refresh_token.blank?

        refresh_token_expires_in = token.params['refresh_token_expires_in'].presence

        {
          refresh_token: token.refresh_token,
          expires_at: token.expires_at,
          refresh_token_expires_at: (Time.current.to_i + refresh_token_expires_in.to_i if refresh_token_expires_in)
        }.compact
      end
    end
  end
end
