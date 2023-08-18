# frozen_string_literal: true

module Gitlab
  module InternalEvents
    module EventDefinitions
      InvalidMetricConfiguration = Class.new(StandardError)

      class << self
        VALID_UNIQUE_VALUES = %w[user.id project.id namespace.id].freeze

        def load_configurations
          @events = load_metric_definitions
          nil
        end

        def unique_property(event_name)
          unique_value = events[event_name]&.to_s

          raise(InvalidMetricConfiguration, "Unique property not defined for #{event_name}") unless unique_value

          unless VALID_UNIQUE_VALUES.include?(unique_value)
            raise(InvalidMetricConfiguration, "Invalid unique value '#{unique_value}' for #{event_name}")
          end

          unique_value.split('.').first.to_sym
        end

        def known_event?(event_name)
          events.key?(event_name)
        end

        private

        def events
          load_configurations if @events.nil? || Gitlab::Usage::MetricDefinition.metric_definitions_changed?

          @events
        end

        def load_metric_definitions
          all_events = {}

          Gitlab::Usage::MetricDefinition.all.each do |metric_definition|
            next unless metric_definition.available?

            process_events(all_events, metric_definition.events)
          rescue StandardError => e
            Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
          end

          all_events
        end

        def process_events(all_events, metric_events)
          metric_events.each do |event_name, event_unique_attribute|
            unless all_events[event_name]
              all_events[event_name] = event_unique_attribute
              next
            end

            next if event_unique_attribute.nil? || event_unique_attribute == all_events[event_name]

            raise InvalidMetricConfiguration,
              "The same event cannot have several unique properties defined. " \
              "Event: #{event_name}, unique values: #{event_unique_attribute}, #{all_events[event_name]}"
          end
        end
      end
    end
  end
end
