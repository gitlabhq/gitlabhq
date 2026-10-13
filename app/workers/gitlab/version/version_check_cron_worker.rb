# frozen_string_literal: true

require "base64"

module Gitlab
  module Version
    class VersionCheckCronWorker
      include ApplicationWorker
      include CronjobQueue # rubocop: disable Scalability/CronWorkerContext -- no relevant metadata

      deduplicate :until_executed
      idempotent!

      data_consistency :sticky

      sidekiq_options retry: 3

      feature_category :service_ping
      urgency :low

      # Keyed on the running version so an upgrade discards the previous
      # version's cached response instead of showing a stale recommendation.
      def self.cache_key
        "version_check:#{Gitlab::VERSION}"
      end

      def perform
        # A redirected destination is typically local, and .try_get would swallow the
        # resulting BlockedUrlError as a nil response. ServicePing::SubmitService
        # allows local requests for the same reason.
        response = Gitlab::HTTP.try_get(url, allow_local_requests: true)

        if response.present? && response.code == 200
          result = Gitlab::Json.parse(response.body)
          Gitlab::AppLogger.info(message: 'Version check succeeded', result: result)

          Rails.cache.write(self.class.cache_key, result)
        else
          Gitlab::AppLogger.error(message: 'Version check failed',
            error: { code: response&.code, message: response&.body })
        end
      rescue JSON::ParserError => e
        Gitlab::AppLogger.error(message: 'Parsing version check response failed',
          error: { message: e.message, code: response&.code })
      end

      private

      def data
        { version: Gitlab::VERSION }
      end

      def url
        encoded_data = Base64.urlsafe_encode64(data.to_json)

        "#{host}/check.json?gitlab_info=#{encoded_data}"
      end

      def host
        Gitlab::TelemetryEndpoint.version_check_url
      end
    end
  end
end
