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
        events = cli.global.events.to_h { |event| [event.file_path, event] } # rubocop:disable Rails/IndexBy -- not rails

        return events if event_paths.none?

        events.slice(*event_paths)
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

      def duplicate_events?(action, events)
        events.count { |event| action == event.action } > 1
      end
    end
  end
end
