# frozen_string_literal: true

# WARNING: This module has been deprecated and will be removed in the future
# Use InternalEvents.track_event instead https://docs.gitlab.com/ee/development/internal_analytics/internal_event_instrumentation/index.html

module Gitlab
  module Tracking
    class << self
      delegate :flush, to: :tracker

      def enabled?
        tracker.enabled?
      end

      def micro_verification_enabled?
        Gitlab::Utils.to_boolean(ENV['VERIFY_TRACKING'], default: false)
      end

      def event(category, action, label: nil, property: nil, value: nil, context: [], project: nil, user: nil, namespace: nil, **extra) # rubocop:disable Metrics/ParameterLists
        action = action.to_s

        project_id = project.is_a?(Integer) ? project : project&.id

        contexts = [
          Tracking::StandardContext.new(
            namespace_id: namespace&.id,
            plan_name: namespace&.actual_plan_name,
            project_id: project_id,
            user: user,
            **extra).to_context, *context
        ]

        track_struct_event(tracker, category, action, label: label, property: property, value: value, contexts: contexts)
      end

      def options(group)
        tracker.options(group)
      end

      def collector_hostname
        tracker.hostname
      end

      def snowplow_micro_enabled?
        Rails.env.development? || micro_verification_enabled?
      end

      def tracker
        @tracker ||= if snowplow_micro_enabled?
                       Gitlab::Tracking::Destinations::SnowplowMicro.new
                     else
                       Gitlab::Tracking::Destinations::Snowplow.new
                     end
      end

      private

      def track_struct_event(destination, category, action, label:, property:, value:, contexts:)
        destination
          .event(category, action, label: label, property: property, value: value, context: contexts)
      rescue StandardError => error
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(error, snowplow_category: category, snowplow_action: action)
      end
    end
  end
end

Gitlab::Tracking.prepend_mod_with('Gitlab::Tracking')
