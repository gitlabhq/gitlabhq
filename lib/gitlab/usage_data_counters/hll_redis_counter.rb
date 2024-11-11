# frozen_string_literal: true

# WARNING: This module has been deprecated and will be removed in the future
# Use InternalEvents.track_event instead https://docs.gitlab.com/ee/development/internal_analytics/internal_event_instrumentation/index.html

module Gitlab
  module UsageDataCounters
    module HLLRedisCounter
      KEY_EXPIRY_LENGTH = 6.weeks
      REDIS_SLOT = 'hll_counters'
      KEY_OVERRIDES_PATH = Rails.root.join('lib/gitlab/usage_data_counters/hll_redis_key_overrides.yml')
      LEGACY_EVENTS_PATH = Rails.root.join('lib/gitlab/usage_data_counters/hll_redis_legacy_events.yml')

      EventError = Class.new(StandardError)
      UnknownEvent = Class.new(EventError)
      UnfinishedEventMigrationError = Class.new(EventError)
      UnknownLegacyEventError = Class.new(EventError)

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
        include Gitlab::Utils::StrongMemoize

        # Track unique events
        #
        # event_name - The event name.
        # values - One or multiple values counted.
        # property_name - Name of the values counted.
        # time - Time of the action, set to Time.current.
        def track_event(event_name, values:, property_name: nil, time: Time.current)
          track(values, event_name, property_name: property_name, time: time)
        end

        # Count unique events for a given time range.
        #
        # event_names - The list of the events to count.
        # property_names - The list of the values for which the events are to be counted.
        # start_date  - The start date of the time range.
        # end_date  - The end date of the time range.
        def unique_events(event_names:, start_date:, end_date:, property_name: nil)
          used_in_aggregate_metric = event_names.is_a?(Array) && event_names.size > 1

          count_unique_events(event_names: event_names, property_name: property_name, start_date: start_date, end_date: end_date, used_in_aggregate_metric: used_in_aggregate_metric)
        end

        def known_event?(event_name)
          known_events.include?(event_name.to_s)
        end

        def known_events
          @known_events ||= load_events
        end

        def legacy_event?(event_name)
          legacy_events.include?(event_name)
        end

        private

        def track(values, event_name, property_name:, time: Time.zone.now)
          unless known_event?(event_name)
            Gitlab::ErrorTracking.track_and_raise_for_dev_exception(UnknownEvent.new("Unknown event #{event_name}"))
            return
          end

          return unless Feature.enabled?(:redis_hll_tracking, type: :ops)

          Gitlab::Redis::HLL.add(key: redis_key(event_with_property_name(event_name, property_name), time, false), value: values, expiry: KEY_EXPIRY_LENGTH)
        rescue StandardError => e
          # Ignore any exceptions unless is dev or test env
          # The application flow should not be blocked by errors in tracking
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
        end

        def count_unique_events(event_names:, start_date:, end_date:, property_name:, used_in_aggregate_metric: false)
          events = events_with_property_names(event_names, property_name)

          keys = keys_for_aggregation(events: events, start_date: start_date, end_date: end_date, used_in_aggregate_metric: used_in_aggregate_metric)

          return FALLBACK unless keys.any?

          redis_usage_data { Gitlab::Redis::HLL.count(keys: keys) }
        end

        def events_with_property_names(event_names, property_name)
          Array(event_names).filter_map do |event_name|
            next unless known_event?(event_name)

            event_with_property_name(event_name, property_name)
          end
        end

        def event_with_property_name(event_name, property_name)
          if property_name
            {
              name: event_name.to_s,
              property_name: property_name
            }
          else
            { name: event_name.to_s }
          end
        end

        def load_events
          events_set = Set.new

          Gitlab::Usage::MetricDefinition.all.each do |d| # rubocop:disable Rails/FindEach -- not an ActiveRecord::Relation
            next unless d.available?

            events_set.merge(d.events.keys)
          end

          events_set
        end

        def redis_key(event, time, used_in_aggregate_metric)
          key = redis_key_base(event, used_in_aggregate_metric)

          year_week = time.strftime('%G-%V')
          "{#{REDIS_SLOT}}_#{key}-#{year_week}"
        end

        def redis_key_base(event, used_in_aggregate_metric)
          event_name = event[:name]
          property_name = event[:property_name]

          validate!(event_name, property_name, used_in_aggregate_metric)

          key = event_name
          legacy_event_with_property_name = used_in_aggregate_metric && legacy_events.include?(event_name)
          if property_name && !legacy_event_with_property_name
            key = "#{key}-#{formatted_property_name(property_name)}"
          end

          key_overrides.fetch(key, key)
        end

        def validate!(event_name, property_name, used_in_aggregate_metric)
          raise UnknownEvent, "Unknown event #{event_name}" unless known_events.include?(event_name.to_s)

          return if used_in_aggregate_metric

          if property_name && legacy_events.include?(event_name)
            link = Rails.application.routes.url_helpers.help_page_url('development/internal_analytics/internal_event_instrumentation/migration.md', anchor: 'backend-1')
            message = "Event #{event_name} has been invoked with property_name.\n" \
                      "When an event gets migrated to Internal Events, its name needs to be removed " \
                      "from hll_redis_legacy_events.yml and added to hll_redis_key_overrides.yml: #{link}"
            Gitlab::ErrorTracking.track_and_raise_for_dev_exception(UnfinishedEventMigrationError.new(message), event_name: event_name)
          elsif !property_name && legacy_events.exclude?(event_name)
            message = "Event #{event_name} has been invoked with no property_name.\n" \
                      "When a new non-internal event gets created, its name needs to be added " \
                      "to the hll_redis_legacy_events.yml file."
            Gitlab::ErrorTracking.track_and_raise_for_dev_exception(UnknownLegacyEventError.new(message), event_name: event_name)
          end
        end

        def formatted_property_name(property_name)
          # simplify to format from EventDefinitions.unique_properties
          property_name.to_s.split('.').first.to_sym
        end

        def key_overrides
          YAML.safe_load(File.read(KEY_OVERRIDES_PATH))
        end

        def legacy_events
          YAML.safe_load(File.read(LEGACY_EVENTS_PATH)).to_set
        end

        strong_memoize_attr :key_overrides
        strong_memoize_attr :legacy_events
      end
    end
  end
end
