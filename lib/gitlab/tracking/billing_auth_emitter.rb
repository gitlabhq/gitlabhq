# frozen_string_literal: true

module Gitlab
  module Tracking
    # Snowplow emitter for billing events that authenticates requests to the
    # DIP collector's protected path using a GCP IAM OIDC Bearer token.
    #
    # The snowplow-tracker gem's emitters do not support custom headers, so we
    # subclass AsyncEmitter and override #http_post (same approach as
    # SnowplowTimeoutEmitter) to inject the Authorization header.
    class BillingAuthEmitter < SnowplowTracker::AsyncEmitter
      extend ::Gitlab::Utils::Override

      HTTP_TIMEOUT = 30

      def initialize(endpoint:, options: {})
        # Guards @token_source memoization: AsyncEmitter runs http_post across a
        # pool of worker threads, so the mutex must exist before they start.
        @token_source_mutex = Mutex.new
        super
      end

      override :http_post
      def http_post(payload)
        logger.info("Sending POST request to #{@collector_uri}...")
        logger.debug("Payload: #{payload}")
        response = Gitlab::HTTP.post(
          @collector_uri,
          body: payload.to_json,
          headers: post_headers,
          open_timeout: HTTP_TIMEOUT,
          read_timeout: HTTP_TIMEOUT
        )
        logger.add(good_status_code?(response.code) ? Logger::INFO : Logger::WARN) do
          "POST request to #{@collector_uri} finished with status code #{response.code}"
        end

        response
      end

      private

      def post_headers
        headers = { 'Content-Type' => 'application/json; charset=utf-8' }
        token = token_source.token

        if token.blank?
          logger.warn('BillingEvents: no OIDC token available, sending request without Authorization header')
        else
          headers['Authorization'] = "Bearer #{token}"
        end

        headers
      end

      def token_source
        return @token_source if @token_source

        @token_source_mutex.synchronize do
          @token_source ||= Gitlab::Tracking::Destinations::BillingOidcTokenSource.new(URI(@collector_uri).host)
        end
      end
    end
  end
end
