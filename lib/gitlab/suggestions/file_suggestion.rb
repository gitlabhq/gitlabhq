# frozen_string_literal: true

module Gitlab
  module Suggestions
    class FileSuggestion
      include Gitlab::Utils::StrongMemoize

      SuggestionForDifferentFileError = Class.new(StandardError)

      attr_reader :file_path
      attr_reader :blob
      attr_reader :suggestions

      def initialize(file_path, suggestions)
        @file_path = file_path
        @suggestions = suggestions.sort_by(&:from_line_index)
        @blob = suggestions.first&.diff_file&.new_blob
      end

      def line_conflict?
        strong_memoize(:line_conflict) do
          _line_conflict?
        end
      end

      def new_content
        @new_content ||= _new_content
      end

      private

      def blob_data_lines
        blob.load_all_data!
        blob.data.lines
      end

      def current_content
        @current_content ||= blob.nil? ? [''] : blob_data_lines
      end

      def _new_content
        current_content.tap do |content|
          # NOTE: We need to cater for line number changes when the range is more than one line.
          offset = 0

          suggestions.each do |suggestion|
            range = line_range(suggestion, offset)
            content[range] = suggestion.to_content
            offset += range.count - 1
          end
        end.join
      end

      def line_range(suggestion, offset = 0)
        (suggestion.from_line_index - offset)..(suggestion.to_line_index - offset)
      end

      def _line_conflict?
        has_conflict = false

        suggestions.each_with_object([]) do |suggestion, ranges|
          range_in_test = line_range(suggestion)

          if has_range_conflict?(range_in_test, ranges)
            has_conflict = true
            break
          end

          ranges << range_in_test
        end

        has_conflict
      end

      def has_range_conflict?(range_in_test, ranges)
        ranges.any? do |range|
          range.overlaps?(range_in_test)
        end
      end
    end
  end
end
