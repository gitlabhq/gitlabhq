# frozen_string_literal: true

module Gitlab
  module Tracking
    SNOWPLOW_NAMESPACE = 'gl'

    class << self
      def enabled?
        snowplow_micro_enabled? || Gitlab::CurrentSettings.snowplow_enabled?
      end

      def event(category, action, label: nil, property: nil, value: nil, context: [], project: nil, user: nil, namespace: nil, **extra) # rubocop:disable Metrics/ParameterLists
        contexts = [Tracking::StandardContext.new(project: project, user: user, namespace: namespace, **extra).to_context, *context]

        snowplow.event(category, action, label: label, property: property, value: value, context: contexts)
      rescue StandardError => error
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(error, snowplow_category: category, snowplow_action: action)
      end

      def options(group)
        snowplow.options(group)
      end

      def collector_hostname
        snowplow.hostname
      end

      private

      def snowplow
        @snowplow ||= if snowplow_micro_enabled?
                        Gitlab::Tracking::Destinations::SnowplowMicro.new
                      else
                        Gitlab::Tracking::Destinations::Snowplow.new
                      end
      end

      def snowplow_micro_enabled?
        Rails.env.development? && Gitlab::Utils.to_boolean(ENV['SNOWPLOW_MICRO_ENABLE'])
      end
    end
  end
end
