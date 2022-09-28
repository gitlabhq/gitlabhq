# frozen_string_literal: true

module ErrorTracking
  class SentryClient
    module Event
      def issue_latest_event(issue_id:)
        latest_event = http_get(api_urls.issue_latest_event_url(issue_id))[:body]

        map_to_event(latest_event)
      end

      private

      def map_to_event(event)
        stack_trace = parse_stack_trace(event)

        Gitlab::ErrorTracking::ErrorEvent.new(
          project_id: event['projectID'],
          issue_id: ensure_numeric!('issue_id', event['groupID']),
          date_received: event['dateReceived'],
          stack_trace_entries: stack_trace
        )
      end

      def parse_stack_trace(event)
        exception_entry = event['entries']&.detect { |h| h['type'] == 'exception' }
        return [] unless exception_entry

        exception_values = exception_entry.dig('data', 'values')
        stack_trace_entry = exception_values&.detect { |h| h['stacktrace'].present? }
        return [] unless stack_trace_entry

        stack_trace_entry.dig('stacktrace', 'frames') || []
      end
    end
  end
end
