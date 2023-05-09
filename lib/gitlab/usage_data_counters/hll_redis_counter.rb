# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    module HLLRedisCounter
      DEFAULT_WEEKLY_KEY_EXPIRY_LENGTH = 6.weeks
      DEFAULT_DAILY_KEY_EXPIRY_LENGTH = 29.days
      REDIS_SLOT = 'hll_counters'

      EventError = Class.new(StandardError)
      UnknownEvent = Class.new(EventError)
      UnknownAggregation = Class.new(EventError)
      AggregationMismatch = Class.new(EventError)
      InvalidContext = Class.new(EventError)

      KNOWN_EVENTS_PATH = File.expand_path('known_events/*.yml', __dir__)
      ALLOWED_AGGREGATIONS = %i(daily weekly).freeze

      # Track event on entity_id
      # Increment a Redis HLL counter for unique event_name and entity_id
      #
      # All events should be added to known_events yml files lib/gitlab/usage_data_counters/known_events/
      #
      # Event example:
      #
      # - name: g_compliance_dashboard # Unique event name
      #   aggregation: weekly          # Aggregation level, keys are stored weekly
      #
      # Usage:
      #
      # * Track event: Gitlab::UsageDataCounters::HLLRedisCounter.track_event('g_compliance_dashboard', values: user_id)
      # * Get unique counts per user: Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(event_names: 'g_compliance_dashboard', start_date: 28.days.ago, end_date: Date.current)
      class << self
        include Gitlab::Utils::UsageData
        include Gitlab::Usage::TimeFrame

        # Track unique events
        #
        # event_name - The event name.
        # values - One or multiple values counted.
        # time - Time of the action, set to Time.current.
        def track_event(event_name, values:, time: Time.current)
          track(values, event_name, time: time)
        end

        # Track unique events
        #
        # event_name - The event name.
        # values - One or multiple values counted.
        # context - Event context, plan level tracking.
        # time - Time of the action, set to Time.current.
        def track_event_in_context(event_name, values:, context:, time: Time.zone.now)
          return if context.blank?
          return unless context.in?(valid_context_list)

          track(values, event_name, context: context, time: time)
        end

        # Count unique events for a given time range.
        #
        # event_names - The list of the events to count.
        # start_date  - The start date of the time range.
        # end_date  - The end date of the time range.
        # context - Event context, plan level tracking. Available if set when tracking.
        def unique_events(event_names:, start_date:, end_date:, context: '')
          count_unique_events(event_names: event_names, start_date: start_date, end_date: end_date, context: context) do |events|
            raise AggregationMismatch, events unless events_same_aggregation?(events)
            raise InvalidContext if context.present? && !context.in?(valid_context_list)
          end
        end

        def known_event?(event_name)
          event_for(event_name).present?
        end

        def known_events
          @known_events ||= load_events(KNOWN_EVENTS_PATH)
        end

        def calculate_events_union(event_names:, start_date:, end_date:)
          count_unique_events(event_names: event_names, start_date: start_date, end_date: end_date) do |events|
            raise AggregationMismatch, events unless events_same_aggregation?(events)
          end
        end

        private

        def track(values, event_name, context: '', time: Time.zone.now)
          return unless ::ServicePing::ServicePingSettings.enabled?

          event = event_for(event_name)
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(UnknownEvent.new("Unknown event #{event_name}")) unless event.present?

          return if event.blank?
          return unless Feature.enabled?(:redis_hll_tracking, type: :ops)

          if event[:aggregation].to_sym == :daily
            weekly_event = event.dup.tap { |e| e['aggregation'] = 'weekly' }
            Gitlab::Redis::HLL.add(key: redis_key(weekly_event, time, context), value: values, expiry: expiry(weekly_event))
          end

          Gitlab::Redis::HLL.add(key: redis_key(event, time, context), value: values, expiry: expiry(event))

        rescue StandardError => e
          # Ignore any exceptions unless is dev or test env
          # The application flow should not be blocked by erros in tracking
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
        end

        # The array of valid context on which we allow tracking
        def valid_context_list
          Plan.all_plans
        end

        def count_unique_events(event_names:, start_date:, end_date:, context: '')
          events = events_for(Array(event_names).map(&:to_s))

          yield events if block_given?

          aggregation = events.first[:aggregation]

          if Feature.disabled?(:revert_daily_hll_events_to_weekly_aggregation)
            aggregation = :weekly
            events.each { |e| e[:aggregation] = :weekly }
          end

          keys = keys_for_aggregation(aggregation, events: events, start_date: start_date, end_date: end_date, context: context)

          return FALLBACK unless keys.any?

          redis_usage_data { Gitlab::Redis::HLL.count(keys: keys) }
        end

        def keys_for_aggregation(aggregation, events:, start_date:, end_date:, context: '')
          if aggregation.to_sym == :daily
            daily_redis_keys(events: events, start_date: start_date, end_date: end_date, context: context)
          else
            weekly_redis_keys(events: events, start_date: start_date, end_date: end_date, context: context)
          end
        end

        def load_events(wildcard)
          Dir[wildcard].each_with_object([]) do |path, events|
            events.push(*load_yaml_from_path(path))
          end
        end

        def load_yaml_from_path(path)
          YAML.safe_load(File.read(path))&.map(&:with_indifferent_access)
        end

        def known_events_names
          known_events.map { |event| event[:name] }
        end

        def events_same_aggregation?(events)
          aggregation = events.first[:aggregation]
          events.all? { |event| event[:aggregation] == aggregation }
        end

        def expiry(event)
          event[:aggregation].to_sym == :daily ? DEFAULT_DAILY_KEY_EXPIRY_LENGTH : DEFAULT_WEEKLY_KEY_EXPIRY_LENGTH
        end

        def event_for(event_name)
          known_events.find { |event| event[:name] == event_name.to_s }
        end

        def events_for(event_names)
          known_events.select { |event| event_names.include?(event[:name]) }
        end

        # Compose the key in order to store events daily or weekly
        def redis_key(event, time, context = '')
          raise UnknownEvent, "Unknown event #{event[:name]}" unless known_events_names.include?(event[:name].to_s)

          # ToDo: remove during https://gitlab.com/groups/gitlab-org/-/epics/9542 cleanup
          raise UnknownAggregation, "Use :daily or :weekly aggregation" unless ALLOWED_AGGREGATIONS.include?(event[:aggregation].to_sym)

          key = "{#{REDIS_SLOT}}_#{event[:name]}"
          key = apply_time_aggregation(key, time, event)
          key = "#{context}_#{key}" if context.present?
          key
        end

        def apply_time_aggregation(key, time, event)
          if event[:aggregation].to_sym == :daily
            year_day = time.strftime('%G-%j')
            "#{year_day}-#{key}"
          else
            year_week = time.strftime('%G-%V')
            "#{key}-#{year_week}"
          end
        end

        def daily_redis_keys(events:, start_date:, end_date:, context: '')
          (start_date.to_date..end_date.to_date).map do |date|
            events.map { |event| redis_key(event, date, context) }
          end.flatten
        end

        def weekly_redis_keys(events:, start_date:, end_date:, context: '')
          end_date = end_date.end_of_week - 1.week
          (start_date.to_date..end_date.to_date).map do |date|
            events.map { |event| redis_key(event, date, context) }
          end.flatten.uniq
        end
      end
    end
  end
end

Gitlab::UsageDataCounters::HLLRedisCounter.prepend_mod_with('Gitlab::UsageDataCounters::HLLRedisCounter')
