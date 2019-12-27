# frozen_string_literal: true

module Gitlab
  module ErrorTracking
    module StackTraceHighlightDecorator
      extend self

      def decorate(error_event)
        ::Gitlab::ErrorTracking::ErrorEvent.new(
          issue_id: error_event.issue_id,
          date_received: error_event.date_received,
          stack_trace_entries: highlight_stack_trace(error_event.stack_trace_entries)
        )
      end

      private

      def highlight_stack_trace(stack_trace)
        stack_trace.map do |entry|
          highlight_stack_trace_entry(entry)
        end
      end

      def highlight_stack_trace_entry(entry)
        return entry unless entry['context']

        entry.merge('context' => highlight_entry_context(entry['filename'], entry['context']))
      end

      def highlight_entry_context(filename, context)
        language = guess_language_by_filename(filename)

        context.map do |line_number, line_of_code|
          [
            line_number,
            # Passing nil for the blob name allows skipping linking dependencies for the line_of_code
            Gitlab::Highlight.highlight(nil, line_of_code, language: language)
          ]
        end
      end

      def guess_language_by_filename(filename)
        Rouge::Lexer.guess_by_filename(filename).tag
      rescue Rouge::Guesser::Ambiguous => e
        e.alternatives.min_by(&:tag)&.tag
      end
    end
  end
end
