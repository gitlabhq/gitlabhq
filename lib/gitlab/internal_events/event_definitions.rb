# frozen_string_literal: true

module Gitlab
  module InternalEvents
    module EventDefinitions
      class << self
        def load_configurations
          @events = load_metric_definitions
          nil
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
