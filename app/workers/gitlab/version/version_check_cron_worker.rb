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

      def perform
        response = Gitlab::HTTP.try_get(url)

        if response.present? && response.code == 200
          result = Gitlab::Json.parse(response.body)
          Gitlab::AppLogger.info(message: 'Version check succeeded', result: result)

          Rails.cache.write("version_check", result)
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
        'https://version.gitlab.com'
      end
    end
  end
end
