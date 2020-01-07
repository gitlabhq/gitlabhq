# frozen_string_literal: true

module Sentry
  class Client
    module Event
      def issue_latest_event(issue_id:)
        latest_event = http_get(issue_latest_event_api_url(issue_id))[:body]

        map_to_event(latest_event)
      end

      private

      def issue_latest_event_api_url(issue_id)
        latest_event_url = URI(url)
        latest_event_url.path = "/api/0/issues/#{issue_id}/events/latest/"

        latest_event_url
      end

      def map_to_event(event)
        stack_trace = parse_stack_trace(event)

        Gitlab::ErrorTracking::ErrorEvent.new(
          issue_id: event.dig('groupID'),
          date_received: event.dig('dateReceived'),
          stack_trace_entries: stack_trace
        )
      end

      def parse_stack_trace(event)
        exception_entry = event.dig('entries')&.detect { |h| h['type'] == 'exception' }
        return [] unless exception_entry

        exception_values = exception_entry.dig('data', 'values')
        stack_trace_entry = exception_values&.detect { |h| h['stacktrace'].present? }
        return [] unless stack_trace_entry

        stack_trace_entry.dig('stacktrace', 'frames') || []
      end
    end
  end
end
