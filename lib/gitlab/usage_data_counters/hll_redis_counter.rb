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
      UnknownAggregationOperator = Class.new(EventError)
      InvalidContext = Class.new(EventError)

      KNOWN_EVENTS_PATH = File.expand_path('known_events/*.yml', __dir__)
      ALLOWED_AGGREGATIONS = %i(daily weekly).freeze
      UNION_OF_AGGREGATED_METRICS = 'OR'
      INTERSECTION_OF_AGGREGATED_METRICS = 'AND'
      ALLOWED_METRICS_AGGREGATIONS = [UNION_OF_AGGREGATED_METRICS, INTERSECTION_OF_AGGREGATED_METRICS].freeze
      AGGREGATED_METRICS_PATH = File.expand_path('aggregated_metrics/*.yml', __dir__)

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
      # * Track event: Gitlab::UsageDataCounters::HLLRedisCounter.track_event(user_id, 'g_compliance_dashboard')
      # * Get unique counts per user: Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(event_names: 'g_compliance_dashboard', start_date: 28.days.ago, end_date: Date.current)
      class << self
        include Gitlab::Utils::UsageData

        def track_event(value, event_name, time = Time.zone.now)
          track(value, event_name, time: time)
        end

        def track_event_in_context(value, event_name, context, time = Time.zone.now)
          return if context.blank?
          return unless context.in?(valid_context_list)

          track(value, event_name, context: context, time: time)
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
              hash["#{event}_weekly"] = unique_events(event_names: [event], start_date: 7.days.ago.to_date, end_date: Date.current)
              hash["#{event}_monthly"] = unique_events(event_names: [event], start_date: 4.weeks.ago.to_date, end_date: Date.current)
            end

            if eligible_for_totals?(events_names)
              event_results["#{category}_total_unique_counts_weekly"] = unique_events(event_names: events_names, start_date: 7.days.ago.to_date, end_date: Date.current)
              event_results["#{category}_total_unique_counts_monthly"] = unique_events(event_names: events_names, start_date: 4.weeks.ago.to_date, end_date: Date.current)
            end

            category_results["#{category}"] = event_results
          end
        end

        def known_event?(event_name)
          event_for(event_name).present?
        end

        def aggregated_metrics_monthly_data
          aggregated_metrics_data(4.weeks.ago.to_date)
        end

        def aggregated_metrics_weekly_data
          aggregated_metrics_data(7.days.ago.to_date)
        end

        def known_events
          @known_events ||= load_events(KNOWN_EVENTS_PATH)
        end

        def aggregated_metrics
          @aggregated_metrics ||= load_events(AGGREGATED_METRICS_PATH)
        end

        private

        def track(value, event_name, context: '', time: Time.zone.now)
          return unless Gitlab::CurrentSettings.usage_ping_enabled?

          event = event_for(event_name)
          raise UnknownEvent, "Unknown event #{event_name}" unless event.present?

          Gitlab::Redis::HLL.add(key: redis_key(event, time, context), value: value, expiry: expiry(event))
        end

        # The aray of valid context on which we allow tracking
        def valid_context_list
          Plan.all_plans
        end

        def aggregated_metrics_data(start_date)
          aggregated_metrics.each_with_object({}) do |aggregation, weekly_data|
            next if aggregation[:feature_flag] && Feature.disabled?(aggregation[:feature_flag], default_enabled: false, type: :development)

            weekly_data[aggregation[:name]] = calculate_count_for_aggregation(aggregation, start_date: start_date, end_date: Date.current)
          end
        end

        def calculate_count_for_aggregation(aggregation, start_date:, end_date:)
          case aggregation[:operator]
          when UNION_OF_AGGREGATED_METRICS
            calculate_events_union(event_names: aggregation[:events], start_date: start_date, end_date: end_date)
          when INTERSECTION_OF_AGGREGATED_METRICS
            calculate_events_intersections(event_names: aggregation[:events], start_date: start_date, end_date: end_date)
          else
            raise UnknownAggregationOperator, "Events should be aggregated with one of operators #{ALLOWED_METRICS_AGGREGATIONS}"
          end
        end

        # calculate intersection of 'n' sets based on inclusion exclusion principle https://en.wikipedia.org/wiki/Inclusion%E2%80%93exclusion_principle
        # this method will be extracted to dedicated module with https://gitlab.com/gitlab-org/gitlab/-/issues/273391
        def calculate_events_intersections(event_names:, start_date:, end_date:, subset_powers_cache: Hash.new({}))
          # calculate power of intersection of all given metrics from inclusion exclusion principle
          # |A + B + C| = (|A| + |B| + |C|) - (|A & B| + |A & C| + .. + |C & D|) + (|A & B & C|)  =>
          # |A & B & C| = - (|A| + |B| + |C|) + (|A & B| + |A & C| + .. + |C & D|) + |A + B + C|
          # |A + B + C + D| = (|A| + |B| + |C| + |D|) - (|A & B| + |A & C| + .. + |C & D|) + (|A & B & C| + |B & C & D|) - |A & B & C & D| =>
          # |A & B & C & D| = (|A| + |B| + |C| + |D|) - (|A & B| + |A & C| + .. + |C & D|) + (|A & B & C| + |B & C & D|) - |A + B + C + D|

          # calculate each components of equation except for the last one |A & B & C & D| = (|A| + |B| + |C| + |D|) - (|A & B| + |A & C| + .. + |C & D|) + (|A & B & C| + |B & C & D|) -  ...
          subset_powers_data = subsets_intersection_powers(event_names, start_date, end_date, subset_powers_cache)

          # calculate last component of the equation  |A & B & C & D| = .... - |A + B + C + D|
          power_of_union_of_all_events = begin
            subset_powers_cache[event_names.size][event_names.join('_+_')] ||= \
              calculate_events_union(event_names: event_names, start_date: start_date, end_date: end_date)
          end

          # in order to determine if part of equation (|A & B & C|, |A & B & C & D|), that represents the intersection that we need to calculate,
          # is positive or negative in particular equation we need to determine if number of subsets is even or odd. Please take a look at two examples below
          # |A + B + C| = (|A| + |B| + |C|) - (|A & B| + |A & C| + .. + |C & D|) + |A & B & C|  =>
          # |A & B & C| = - (|A| + |B| + |C|) + (|A & B| + |A & C| + .. + |C & D|) + |A + B + C|
          # |A + B + C + D| = (|A| + |B| + |C| + |D|) - (|A & B| + |A & C| + .. + |C & D|) + (|A & B & C| + |B & C & D|) - |A & B & C & D| =>
          # |A & B & C & D| = (|A| + |B| + |C| + |D|) - (|A & B| + |A & C| + .. + |C & D|) + (|A & B & C| + |B & C & D|) - |A + B + C + D|
          subset_powers_size_even = subset_powers_data.size.even?

          # sum all components of equation except for the last one |A & B & C & D| = (|A| + |B| + |C| + |D|) - (|A & B| + |A & C| + .. + |C & D|) + (|A & B & C| + |B & C & D|) -  ... =>
          sum_of_all_subset_powers = sum_subset_powers(subset_powers_data, subset_powers_size_even)

          # add last component of the equation |A & B & C & D| = sum_of_all_subset_powers - |A + B + C + D|
          sum_of_all_subset_powers + (subset_powers_size_even ? power_of_union_of_all_events : -power_of_union_of_all_events)
        end

        def sum_subset_powers(subset_powers_data, subset_powers_size_even)
          sum_without_sign =  subset_powers_data.to_enum.with_index.sum do |value, index|
            (index + 1).odd? ? value : -value
          end

          (subset_powers_size_even ? -1 : 1) * sum_without_sign
        end

        def subsets_intersection_powers(event_names, start_date, end_date, subset_powers_cache)
          subset_sizes = (1..(event_names.size - 1))

          subset_sizes.map do |subset_size|
            if subset_size > 1
              # calculate sum of powers of intersection between each subset (with given size) of metrics:  #|A + B + C + D| = ... - (|A & B| + |A & C| + .. + |C & D|)
              event_names.combination(subset_size).sum do |events_subset|
                subset_powers_cache[subset_size][events_subset.join('_&_')] ||= \
                  calculate_events_intersections(event_names: events_subset, start_date: start_date, end_date: end_date, subset_powers_cache: subset_powers_cache)
              end
            else
              # calculate sum of powers of each set (metric) alone  #|A + B + C + D| = (|A| + |B| + |C| + |D|) - ...
              event_names.sum do |event|
                subset_powers_cache[subset_size][event] ||= \
                  unique_events(event_names: event, start_date: start_date, end_date: end_date)
              end
            end
          end
        end

        def calculate_events_union(event_names:, start_date:, end_date:)
          count_unique_events(event_names: event_names, start_date: start_date, end_date: end_date) do |events|
            raise SlotMismatch, events unless events_in_same_slot?(events)
            raise AggregationMismatch, events unless events_same_aggregation?(events)
          end
        end

        def count_unique_events(event_names:, start_date:, end_date:, context: '')
          events = events_for(Array(event_names).map(&:to_s))

          yield events if block_given?

          aggregation = events.first[:aggregation]

          keys = keys_for_aggregation(aggregation, events: events, start_date: start_date, end_date: end_date, context: context)
          redis_usage_data { Gitlab::Redis::HLL.count(keys: keys) }
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
          raise UnknownEvent.new("Unknown event #{event[:name]}") unless known_events_names.include?(event[:name].to_s)
          raise UnknownAggregation.new("Use :daily or :weekly aggregation") unless ALLOWED_AGGREGATIONS.include?(event[:aggregation].to_sym)

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

        def validate_aggregation_operator!(operator)
          return true if ALLOWED_METRICS_AGGREGATIONS.include?(operator)

          raise UnknownAggregationOperator.new("Events should be aggregated with one of operators #{ALLOWED_METRICS_AGGREGATIONS}")
        end

        def weekly_redis_keys(events:, start_date:, end_date:, context: '')
          weeks = end_date.to_date.cweek - start_date.to_date.cweek
          weeks = 1 if weeks == 0

          (0..(weeks - 1)).map do |week_increment|
            events.map { |event| redis_key(event, start_date + week_increment * 7.days, context) }
          end.flatten
        end
      end
    end
  end
end

Gitlab::UsageDataCounters::HLLRedisCounter.prepend_if_ee('EE::Gitlab::UsageDataCounters::HLLRedisCounter')
