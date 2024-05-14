# frozen_string_literal: true

# Helpers related to listing existing event definitions
module InternalEventsCli
  module Helpers
    module EventOptions
      def get_event_options(events)
        options = events.filter_map do |(path, event)|
          next if duplicate_events?(event.action, events.values)

          description = format_help(" - #{trim_description(event.description)}")

          {
            name: "#{format_event_name(event)}#{description}",
            value: path
          }
        end

        options.sort_by do |option|
          category = events.dig(option[:value], 'category')
          internal_events = events.dig(option[:value], 'internal_events')

          event_sort_param(internal_events, category, option[:name])
        end
      end

      def events_by_filepath(event_paths = [])
        event_paths = load_event_paths if event_paths.none?

        get_existing_events_for_paths(event_paths)
      end

      private

      def trim_description(description)
        return description if description.to_s.length < 50

        "#{description[0, 50]}..."
      end

      def format_event_name(event)
        if event.internal_events || event.category == 'default'
          event.action
        else
          "#{event.category}:#{event.action}"
        end
      end

      def event_sort_param(internal_events, category, name)
        return "0#{name}" if internal_events
        return "1#{name}" if category == 'default'

        "2#{category}#{name}"
      end

      def get_existing_events_for_paths(event_paths)
        event_paths.each_with_object({}) do |filepath, events|
          details = YAML.safe_load(File.read(filepath))
          fields = InternalEventsCli::NEW_EVENT_FIELDS.map(&:to_s)

          events[filepath] = Event.new(**details.slice(*fields))
        rescue StandardError => e
          cli.say format_error "Encountered an error while loading #{filepath}: #{e.message}"
        end
      end

      def duplicate_events?(action, events)
        events.count { |event| action == event.action } > 1
      end

      def load_event_paths
        [
          Dir["config/events/*.yml"],
          Dir["ee/config/events/*.yml"]
        ].flatten
      end
    end
  end
end
