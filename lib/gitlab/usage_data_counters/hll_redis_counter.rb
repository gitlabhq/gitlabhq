# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    module HLLRedisCounter
      DEFAULT_WEEKLY_KEY_EXPIRY_LENGTH = 6.weeks
      DEFAULT_DAILY_KEY_EXPIRY_LENGTH = 29.days
      DEFAULT_REDIS_SLOT = ''.freeze

      UnknownEvent = Class.new(StandardError)
      UnknownAggregation = Class.new(StandardError)

      KNOWN_EVENTS_PATH = 'lib/gitlab/usage_data_counters/known_events.yml'.freeze
      ALLOWED_AGGREGATIONS = %i(daily weekly).freeze

      # Track event on entity_id
      # Increment a Redis HLL counter for unique event_name and entity_id
      #
      # All events should be added to know_events file lib/gitlab/usage_data_counters/known_events.yml
      #
      # Event example:
      #
      # - name: g_compliance_dashboard # Unique event name
      #   redis_slot: compliance       # Optional slot name, if not defined it will use name as a slot, used for totals
      #   category: compliance         # Group events in categories
      #   expiry: 29                   # Optional expiration time in days, default value 29 days for daily and 6.weeks for weekly
      #   aggregation: daily           # Aggregation level, keys are stored daily or weekly
      #
      # Usage:
      #
      # * Track event: Gitlab::UsageDataCounters::HLLRedisCounter.track_event(user_id, 'g_compliance_dashboard')
      # * Get unique counts per user: Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(event_names: 'g_compliance_dashboard', start_date: 28.days.ago, end_date: Date.current)
      class << self
        def track_event(entity_id, event_name, time = Time.zone.now)
          event = event_for(event_name)

          raise UnknownEvent.new("Unknown event #{event_name}") unless event.present?

          Gitlab::Redis::HLL.add(key: redis_key(event, time), value: entity_id, expiry: expiry(event))
        end

        def unique_events(event_names:, start_date:, end_date:)
          events = events_for(Array(event_names))

          raise 'Events should be in same slot' unless events_in_same_slot?(events)
          raise 'Events should be in same category' unless events_in_same_category?(events)
          raise 'Events should have same aggregation level' unless events_same_aggregation?(events)

          aggregation = events.first[:aggregation]

          keys = keys_for_aggregation(aggregation, events: events, start_date: start_date, end_date: end_date)

          Gitlab::Redis::HLL.count(keys: keys)
        end

        def events_for_category(category)
          known_events.select { |event| event[:category] == category }.map { |event| event[:name] }
        end

        private

        def keys_for_aggregation(aggregation, events:, start_date:, end_date:)
          if aggregation.to_sym == :daily
            daily_redis_keys(events: events, start_date: start_date, end_date: end_date)
          else
            weekly_redis_keys(events: events, start_date: start_date, end_date: end_date)
          end
        end

        def known_events
          @known_events ||= YAML.load_file(Rails.root.join(KNOWN_EVENTS_PATH)).map(&:with_indifferent_access)
        end

        def known_events_names
          known_events.map { |event| event[:name] }
        end

        def events_in_same_slot?(events)
          slot = events.first[:redis_slot]
          events.all? { |event| event[:redis_slot] == slot }
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
          known_events.find { |event| event[:name] == event_name }
        end

        def events_for(event_names)
          known_events.select { |event| event_names.include?(event[:name]) }
        end

        def redis_slot(event)
          event[:redis_slot] || DEFAULT_REDIS_SLOT
        end

        # Compose the key in order to store events daily or weekly
        def redis_key(event, time)
          raise UnknownEvent.new("Unknown event #{event[:name]}") unless known_events_names.include?(event[:name].to_s)
          raise UnknownAggregation.new("Use :daily or :weekly aggregation") unless ALLOWED_AGGREGATIONS.include?(event[:aggregation].to_sym)

          slot = redis_slot(event)
          key = if slot.present?
                  event[:name].to_s.gsub(slot, "{#{slot}}")
                else
                  "{#{event[:name]}}"
                end

          if event[:aggregation].to_sym == :daily
            year_day = time.strftime('%G-%j')
            "#{year_day}-#{key}"
          else
            year_week = time.strftime('%G-%V')
            "#{key}-#{year_week}"
          end
        end

        def daily_redis_keys(events:, start_date:, end_date:)
          (start_date.to_date..end_date.to_date).map do |date|
            events.map { |event| redis_key(event, date) }
          end.flatten
        end

        def weekly_redis_keys(events:, start_date:, end_date:)
          weeks = end_date.to_date.cweek - start_date.to_date.cweek
          weeks = 1 if weeks == 0

          (0..(weeks - 1)).map do |week_increment|
            events.map { |event| redis_key(event, start_date + week_increment * 7.days) }
          end.flatten
        end
      end
    end
  end
end
