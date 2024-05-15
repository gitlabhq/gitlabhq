# frozen_string_literal: true

module Gitlab
  module Database
    module Reindexing
      # This can be used to send annotations for reindexing to a Grafana API
      class GrafanaNotifier
        def initialize(api_key: nil, api_url: nil, additional_tag: nil)
          @api_key = api_key || default_api_key
          @api_url = api_url || default_api_url
          @additional_tag = additional_tag || default_additional_tag
        end

        def notify_start(action)
          return unless enabled?

          payload = base_payload(action).merge(
            text: "Started reindexing of #{action.index.name} on #{action.index.tablename}"
          )

          annotate(payload)
        end

        def notify_end(action)
          return unless enabled?

          payload = base_payload(action).merge(
            text: "Finished reindexing of #{action.index.name} on #{action.index.tablename} (#{action.state})",
            timeEnd: (action.action_end.utc.to_f * 1000).to_i,
            isRegion: true
          )

          annotate(payload)
        end

        private

        def default_api_key
          Gitlab::CurrentSettings.database_grafana_api_key || ENV['GITLAB_GRAFANA_API_KEY']
        end

        def default_api_url
          Gitlab::CurrentSettings.database_grafana_api_url || ENV['GITLAB_GRAFANA_API_URL']
        end

        def default_additional_tag
          Gitlab::CurrentSettings.database_grafana_tag || ENV['GITLAB_REINDEXING_GRAFANA_TAG'] || Rails.env
        end

        def base_payload(action)
          {
            time: (action.action_start.utc.to_f * 1000).to_i,
            tags: ['reindex', @additional_tag.presence, action.index.tablename, action.index.name].compact
          }
        end

        def annotate(payload)
          headers = {
            "Content-Type": "application/json",
            Authorization: "Bearer #{@api_key}"
          }

          success = Gitlab::HTTP.post(
            "#{@api_url}/api/annotations", body: payload.to_json, headers: headers, allow_local_requests: true
          ).success?

          log_error("Response code #{response.code}") unless success

          success
        rescue StandardError => err
          log_error(err)

          false
        end

        def log_error(err)
          Gitlab::AppLogger.warn("Unable to notify Grafana from #{self.class}: #{err}")
        end

        def enabled?
          !(@api_url.blank? || @api_key.blank?)
        end
      end
    end
  end
end
