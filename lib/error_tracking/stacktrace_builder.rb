# frozen_string_literal: true

module ErrorTracking
  class StacktraceBuilder
    attr_reader :stacktrace

    def initialize(payload)
      @stacktrace = build_stacktrace(payload)
    end

    private

    def build_stacktrace(payload)
      raw_stacktrace = raw_stacktrace_from_payload(payload)
      return [] unless raw_stacktrace

      raw_stacktrace.map do |entry|
        {
          'lineNo' => entry['lineno'],
          'context' => build_stacktrace_context(entry),
          'filename' => entry['filename'],
          'abs_path' => entry['abs_path'],
          'function' => entry['function'],
          'colNo' => 0 # we don't support colNo yet.
        }
      end
    end

    def raw_stacktrace_from_payload(payload)
      exception_entry = payload['exception']
      return unless exception_entry

      # Some SDK send exception payload as Array. For exmple Go lang SDK.
      # We need to convert it to hash format we expect.
      exception_entry = { 'values' => exception_entry } if exception_entry.is_a?(Array)

      exception_values = exception_entry['values']
      stack_trace_entry = exception_values&.detect { |h| h['stacktrace'].present? }
      stack_trace_entry&.dig('stacktrace', 'frames')
    end

    def build_stacktrace_context(entry)
      error_line = entry['context_line']
      error_line_no = entry['lineno']
      pre_context = entry['pre_context']
      post_context = entry['post_context']

      context = []
      context.concat lines_with_position(pre_context, error_line_no - pre_context.size) if pre_context
      context.concat lines_with_position([error_line], error_line_no)
      context.concat lines_with_position(post_context, error_line_no + 1) if post_context

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
end
