# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    module HLLRedisCounter
      DEFAULT_WEEKLY_KEY_EXPIRY_LENGTH = 6.weeks
      DEFAULT_DAILY_KEY_EXPIRY_LENGTH = 29.days
      DEFAULT_REDIS_SLOT = ''

      EventError = Class.new(StandardError)
      UnknownEvent = Class.new(EventError)
      UnknownAggregation = Class.new(EventError)
      AggregationMismatch = Class.new(EventError)
      SlotMismatch = Class.new(EventError)
      CategoryMismatch = Class.new(EventError)
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
      #   redis_slot: compliance       # Optional slot name, if not defined it will use name as a slot, used for totals
      #   category: compliance         # Group events in categories
      #   expiry: 29                   # Optional expiration time in days, default value 29 days for daily and 6.weeks for weekly
      #   aggregation: daily           # Aggregation level, keys are stored daily or weekly
      #   feature_flag:                # The event feature flag
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

        def unique_events(event_names:, start_date:, end_date:, context: '')
          count_unique_events(event_names: event_names, start_date: start_date, end_date: end_date, context: context) do |events|
            raise SlotMismatch, events unless events_in_same_slot?(events)
            raise CategoryMismatch, events unless events_in_same_category?(events)
            raise AggregationMismatch, events unless events_same_aggregation?(events)
            raise InvalidContext if context.present? && !context.in?(valid_context_list)
          end
        end

        def categories
          @categories ||= known_events.map { |event| event[:category] }.uniq
        end

        # @param category [String] the category name
        # @return [Array<String>] list of event names for given category
        def events_for_category(category)
          known_events.select { |event| event[:category] == category.to_s }.map { |event| event[:name] }
        end

        def unique_events_data
          categories.each_with_object({}) do |category, category_results|
            events_names = events_for_category(category)

            event_results = events_names.each_with_object({}) do |event, hash|
              hash["#{event}_weekly"] = unique_events(**weekly_time_range.merge(event_names: [event]))
              hash["#{event}_monthly"] = unique_events(**monthly_time_range.merge(event_names: [event]))
            end

            if eligible_for_totals?(events_names)
              event_results["#{category}_total_unique_counts_weekly"] = unique_events(**weekly_time_range.merge(event_names: events_names))
              event_results["#{category}_total_unique_counts_monthly"] = unique_events(**monthly_time_range.merge(event_names: events_names))
            end

            category_results["#{category}"] = event_results
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
            raise SlotMismatch, events unless events_in_same_slot?(events)
            raise AggregationMismatch, events unless events_same_aggregation?(events)
          end
        end

        private

        def track(values, event_name, context: '', time: Time.zone.now)
          return unless usage_ping_enabled?

          event = event_for(event_name)
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(UnknownEvent.new("Unknown event #{event_name}")) unless event.present?

          return unless feature_enabled?(event)

          Gitlab::Redis::HLL.add(key: redis_key(event, time, context), value: values, expiry: expiry(event))
        rescue StandardError => e
          # Ignore any exceptions unless is dev or test env
          # The application flow should not be blocked by erros in tracking
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
        end

        def usage_ping_enabled?
          Gitlab::CurrentSettings.usage_ping_enabled?
        end

        # The array of valid context on which we allow tracking
        def valid_context_list
          Plan.all_plans
        end

        def count_unique_events(event_names:, start_date:, end_date:, context: '')
          events = events_for(Array(event_names).map(&:to_s))

          yield events if block_given?

          aggregation = events.first[:aggregation]

          keys = keys_for_aggregation(aggregation, events: events, start_date: start_date, end_date: end_date, context: context)

          return FALLBACK unless keys.any?

          redis_usage_data { Gitlab::Redis::HLL.count(keys: keys) }
        end

        def feature_enabled?(event)
          return true if event[:feature_flag].blank?

          Feature.enabled?(event[:feature_flag], default_enabled: :yaml) && Feature.enabled?(:redis_hll_tracking, type: :ops, default_enabled: :yaml)
        end

        # Allow to add totals for events that are in the same redis slot, category and have the same aggregation level
        # and if there are more than 1 event
        def eligible_for_totals?(events_names)
          return false if events_names.size <= 1

          events = events_for(events_names)
          events_in_same_slot?(events) && events_in_same_category?(events) && events_same_aggregation?(events)
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

        def events_in_same_slot?(events)
          # if we check one event then redis_slot is only one to check
          return true if events.size == 1

          slot = events.first[:redis_slot]
          events.all? { |event| event[:redis_slot].present? && event[:redis_slot] == slot }
        end

        def events_in_same_category?(events)
          category = events.first[:category]
          events.all? { |event| event[:category] == category }
        end

        def events_same_aggregation?(events)
          aggregation = events.first[:aggregation]
          events.all? { |event| event[:aggregation] == aggregation }
        end

        def expiry(event)
          return event[:expiry].days if event[:expiry].present?

          event[:aggregation].to_sym == :daily ? DEFAULT_DAILY_KEY_EXPIRY_LENGTH : DEFAULT_WEEKLY_KEY_EXPIRY_LENGTH
        end

        def event_for(event_name)
          known_events.find { |event| event[:name] == event_name.to_s }
        end

        def events_for(event_names)
          known_events.select { |event| event_names.include?(event[:name]) }
        end

        def redis_slot(event)
          event[:redis_slot] || DEFAULT_REDIS_SLOT
        end

        # Compose the key in order to store events daily or weekly
        def redis_key(event, time, context = '')
          raise UnknownEvent, "Unknown event #{event[:name]}" unless known_events_names.include?(event[:name].to_s)
          raise UnknownAggregation, "Use :daily or :weekly aggregation" unless ALLOWED_AGGREGATIONS.include?(event[:aggregation].to_sym)

          key = apply_slot(event)
          key = apply_time_aggregation(key, time, event)
          key = "#{context}_#{key}" if context.present?
          key
        end

        def apply_slot(event)
          slot = redis_slot(event)
          if slot.present?
            event[:name].to_s.gsub(slot, "{#{slot}}")
          else
            "{#{event[:name]}}"
          end
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
