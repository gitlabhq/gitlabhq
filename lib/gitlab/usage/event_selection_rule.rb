# frozen_string_literal: true

#   Represents the relationship between a event definition and a metric definition.
#
#   Example usages:
#   EventSelectionRule.new('pull_package', time_framed: true, filter: { label: 'rubygems' })
#
#   The above rule represents a defines a metric that "counts weekly number of pull_package events with label rubygems"
#
#   EventSelectionRule.new('pull_package', time_framed: false)
#
#   The above rule represents a defines a metric that "counts the total number of pull_package events"
#
module Gitlab
  module Usage
    class EventSelectionRule
      include Gitlab::Usage::TimeSeriesStorable
      include Gitlab::Usage::TimeFrame

      TOTAL_COUNTER_KEY_PREFIX = "event_counters"
      SUM_KEY_PREFIX = "event_sums"

      attr_reader :filter, :name, :unique_identifier_name, :operator

      def initialize(name:, time_framed:, filter: {}, unique_identifier_name: nil, operator: nil)
        @name = name
        @time_framed = time_framed
        @filter = filter || {}
        @unique_identifier_name = unique_identifier_name
        @operator = operator
      end

      def redis_key_for_date(date = Date.today)
        redis_key(nil, date)
      end

      def redis_keys_for_time_frame(time_frame)
        if time_frame == 'all'
          [redis_key]
        else
          keys_for_aggregation(events: [path_part_of_redis_key], **time_constraint(time_frame))
        end
      end

      def time_framed?
        @time_framed
      end

      def total_counter?
        unique_identifier_name.nil? && !sum?
      end

      def sum?
        operator.present?
      end

      def matches?(additional_properties)
        filter.all? do |property_name, value|
          additional_properties[property_name] == value
        end
      end

      # Implementing `==` to make sure that `a == b` is true if and only if `a` and `b` have equal properties
      # Checks equality by comparing each attribute.
      # @param [Object] Object to be compared
      def ==(other)
        other.is_a?(self.class) &&
          name == other.name &&
          time_framed? == other.time_framed? &&
          filter == other.filter &&
          unique_identifier_name == other.unique_identifier_name &&
          operator == other.operator
      end

      alias_method :eql?, :==

      # Calculates hash code according to all attributes.
      # @return [Integer] Hash code
      # Ensures 2 objects with the same attributes can't be keys
      # in the same hash twice
      def hash
        [name, time_framed?, filter, unique_identifier_name, operator].hash
      end

      private

      def redis_key(_event_name = nil, date = Date.today, _used_in_aggregate_metric = false)
        return base_key unless time_framed?

        apply_time_aggregation(base_key, date)
      end

      def base_key
        @base_key ||= "{#{redis_slot}}_" + path_part_of_redis_key
      end

      def redis_slot
        return SUM_KEY_PREFIX if sum?

        total_counter? ? TOTAL_COUNTER_KEY_PREFIX : Gitlab::UsageDataCounters::HLLRedisCounter::REDIS_SLOT
      end

      def time_constraint(time_frame)
        case time_frame
        when '28d'
          monthly_time_range
        when '7d'
          weekly_time_range
        else
          raise "Unknown time frame: #{time_frame}"
        end
      end

      def path_part_of_redis_key
        path = name

        if sum?
          # operator should be serialized and used in the path here
          path = "#{path}-operator:#{operator}"
        end

        if filter.present?
          sorted_filter_keys = filter.keys.sort
          serialized_filter = sorted_filter_keys.map { |key| "#{key}:#{filter[key]}" }.join(',')
          path = "#{path}-filter:[#{serialized_filter}]"
        end

        path = "#{path}-#{unique_identifier_name}" if unique_identifier_name.present?

        key_overrides.fetch(path, path)
      end

      def key_overrides
        YAML.safe_load(File.read(Gitlab::UsageDataCounters::HLLRedisCounter::KEY_OVERRIDES_PATH))
      end
    end
  end
end
