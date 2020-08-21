# frozen_string_literal: true

module ProductAnalytics
  class Tracker
    # The file is located in the /public directory
    URL = Gitlab.config.gitlab.url + '/-/sp.js'

    # The collector URL minus protocol and /i
    COLLECTOR_URL = Gitlab.config.gitlab.url.sub(/\Ahttps?\:\/\//, '') + '/-/collector'

    class << self
      include Gitlab::Utils::StrongMemoize

      def event(category, action, label: nil, property: nil, value: nil, context: nil)
        return unless enabled?

        snowplow.track_struct_event(category, action, label, property, value, context, (Time.now.to_f * 1000).to_i)
      end

      private

      def enabled?
        Gitlab::CurrentSettings.usage_ping_enabled?
      end

      def project_id
        Gitlab::CurrentSettings.self_monitoring_project_id
      end

      def snowplow
        strong_memoize(:snowplow) do
          SnowplowTracker::Tracker.new(
            SnowplowTracker::AsyncEmitter.new(COLLECTOR_URL, protocol: Gitlab.config.gitlab.protocol),
            SnowplowTracker::Subject.new,
            Gitlab::Tracking::SNOWPLOW_NAMESPACE,
            project_id.to_s
          )
        end
      end
    end
  end
end
