# frozen_string_literal: true

module Gitlab
  module Auth
    module Atlassian
      class TokenRefresher
        attr_reader :identity

        REFRESH_TOKEN_URL = 'https://auth.atlassian.com/oauth/token'
        MIN_TIME_ALLOWED_TILL_EXPIRE = 5.minutes
        AtlassianTokenRefreshError = Class.new(StandardError)

        def initialize(identity)
          @identity = identity
        end

        def needs_refresh?
          identity.expires_at < MIN_TIME_ALLOWED_TILL_EXPIRE.from_now
        end

        def refresh!
          response = Gitlab::HTTP.post(REFRESH_TOKEN_URL, body: payload.to_json, headers: headers)
          raise AtlassianTokenRefreshError, response["error"] unless response.success?

          identity.update!(
            expires_at: Time.zone.now + response["expires_in"].seconds,
            refresh_token: response["refresh_token"],
            token: response["access_token"]
          )
        end

        def refresh_if_needed!
          refresh! if needs_refresh?
        end

        private

        def headers
          { 'Content-Type' => 'application/json' }
        end

        def payload
          {
            grant_type: 'refresh_token',
            client_id: config.app_id,
            client_secret: config.app_secret,
            refresh_token: identity.refresh_token
          }
        end

        def config
          @config ||= Gitlab::Auth::OAuth::Provider.config_for('atlassian_oauth2')
        end
      end
    end
  end
end
