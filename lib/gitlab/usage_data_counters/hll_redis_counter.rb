# frozen_string_literal: true

# WARNING: This module has been deprecated and will be removed in the future
# Use InternalEvents.track_event instead https://docs.gitlab.com/ee/development/internal_analytics/internal_event_instrumentation/index.html

module Gitlab
  module UsageDataCounters
    module HLLRedisCounter
      KEY_EXPIRY_LENGTH = 6.weeks
      REDIS_SLOT = 'hll_counters'

      EventError = Class.new(StandardError)
      UnknownEvent = Class.new(EventError)

      # Track event on entity_id
      # Increment a Redis HLL counter for unique event_name and entity_id
      #
      # Usage:
      # * Track event: Gitlab::UsageDataCounters::HLLRedisCounter.track_event('g_compliance_dashboard', values: user_id)
      # * Get unique counts per user: Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(event_names: 'g_compliance_dashboard', start_date: 28.days.ago, end_date: Date.current)
      class << self
        include Gitlab::Utils::UsageData
        include Gitlab::Usage::TimeFrame
        include Gitlab::Usage::TimeSeriesStorable

        # Track unique events
        #
        # event_name - The event name.
        # values - One or multiple values counted.
        # time - Time of the action, set to Time.current.
        def track_event(event_name, values:, time: Time.current)
          track(values, event_name, time: time)
        end

        # Count unique events for a given time range.
        #
        # event_names - The list of the events to count.
        # start_date  - The start date of the time range.
        # end_date  - The end date of the time range.
        def unique_events(event_names:, start_date:, end_date:)
          count_unique_events(event_names: event_names, start_date: start_date, end_date: end_date)
        end

        def known_event?(event_name)
          event_for(event_name).present?
        end

        def known_events
          @known_events ||= load_events
        end

        def calculate_events_union(event_names:, start_date:, end_date:)
          count_unique_events(event_names: event_names, start_date: start_date, end_date: end_date)
        end

        private

        def track(values, event_name, time: Time.zone.now)
          event = event_for(event_name)
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(UnknownEvent.new("Unknown event #{event_name}")) unless event.present?

          return if event.blank?
          return unless Feature.enabled?(:redis_hll_tracking, type: :ops)

          Gitlab::Redis::HLL.add(key: redis_key(event, time), value: values, expiry: KEY_EXPIRY_LENGTH)

        rescue StandardError => e
          # Ignore any exceptions unless is dev or test env
          # The application flow should not be blocked by errors in tracking
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
        end

        def count_unique_events(event_names:, start_date:, end_date:)
          events = events_for(Array(event_names).map(&:to_s))

          keys = keys_for_aggregation(events: events, start_date: start_date, end_date: end_date)

          return FALLBACK unless keys.any?

          redis_usage_data { Gitlab::Redis::HLL.count(keys: keys) }
        end

        def load_events
          events = Gitlab::Usage::MetricDefinition.all.map do |d|
            next unless d.available?

            d.attributes[:options] && d.attributes[:options][:events]
          end.flatten.compact.uniq

          events.map do |e|
            { name: e }.with_indifferent_access
          end
        end

        def known_events_names
          @known_events_names ||= known_events.map { |event| event[:name] }
        end

        def event_for(event_name)
          known_events.find { |event| event[:name] == event_name.to_s }
        end

        def events_for(event_names)
          known_events.select { |event| event_names.include?(event[:name]) }
        end

        def redis_key(event, time)
          raise UnknownEvent, "Unknown event #{event[:name]}" unless known_events_names.include?(event[:name].to_s)

          key = "{#{REDIS_SLOT}}_#{event[:name]}"

          year_week = time.strftime('%G-%V')
          "#{key}-#{year_week}"
        end
      end
    end
  end
end
