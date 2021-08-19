# frozen_string_literal: true

class ErrorTracking::ErrorEvent < ApplicationRecord
  belongs_to :error, counter_cache: :events_count

  validates :payload, json_schema: { filename: 'error_tracking_event_payload' }

  validates :error, presence: true
  validates :description, presence: true
  validates :occurred_at, presence: true

  def stacktrace
    @stacktrace ||= build_stacktrace
  end

  # For compatibility with sentry integration
  def to_sentry_error_event
    Gitlab::ErrorTracking::ErrorEvent.new(
      issue_id: error_id,
      date_received: occurred_at,
      stack_trace_entries: stacktrace
    )
  end

  private

  def build_stacktrace
    raw_stacktrace = find_stacktrace_from_payload

    return [] unless raw_stacktrace

    raw_stacktrace.map do |entry|
      {
        'lineNo' => entry['lineno'],
        'context' => build_stacktrace_context(entry),
        'filename' => entry['filename'],
        'function' => entry['function'],
        'colNo' => 0 # we don't support colNo yet.
      }
    end
  end

  def find_stacktrace_from_payload
    exception_entry = payload.dig('exception')

    if exception_entry
      exception_values = exception_entry.dig('values')
      stack_trace_entry = exception_values&.detect { |h| h['stacktrace'].present? }
      stack_trace_entry&.dig('stacktrace', 'frames')
    end
  end

  def build_stacktrace_context(entry)
    context = []
    error_line = entry['context_line']
    error_line_no = entry['lineno']
    pre_context = entry['pre_context']
    post_context = entry['post_context']

    context += lines_with_position(pre_context, error_line_no - pre_context.size)
    context += lines_with_position([error_line], error_line_no)
    context += lines_with_position(post_context, error_line_no + 1)

    context.reject(&:blank?)
  end

  def lines_with_position(lines, position)
    return [] if lines.blank?

    lines.map.with_index do |line, index|
      next unless line

      [position + index, line]
    end
  end
end
