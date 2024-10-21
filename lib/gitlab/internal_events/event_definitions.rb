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

        def unique_properties(event_name)
          unique_values = events.fetch(event_name, [])

          unique_values.filter_map do |unique_value|
            next unless unique_value # legacy events include `nil` unique_value

            unique_value = unique_value.to_s

            unless VALID_UNIQUE_VALUES.include?(unique_value)
              raise(InvalidMetricConfiguration, "Invalid unique value '#{unique_value}' for #{event_name}")
            end

            unique_value.split('.').first.to_sym
          end
        end

        private

        def events
          load_configurations if @events.nil?

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
          metric_events.each do |event_name, event_unique_property|
            all_events[event_name] ||= []

            next if all_events[event_name].include?(event_unique_property)

            all_events[event_name] << event_unique_property
          end
        end
      end
    end
  end
end
