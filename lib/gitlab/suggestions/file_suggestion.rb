# frozen_string_literal: true

module Gitlab
  module Suggestions
    class FileSuggestion
      include Gitlab::Utils::StrongMemoize

      SuggestionForDifferentFileError = Class.new(StandardError)

      def initialize
        @suggestions = []
      end

      def add_suggestion(new_suggestion)
        if for_different_file?(new_suggestion)
          raise SuggestionForDifferentFileError,
                'Only add suggestions for the same file.'
        end

        suggestions << new_suggestion
      end

      def line_conflict?
        strong_memoize(:line_conflict) do
          _line_conflict?
        end
      end

      def new_content
        @new_content ||= _new_content
      end

      def file_path
        @file_path ||= _file_path
      end

      private

      attr_accessor :suggestions

      def blob
        first_suggestion&.diff_file&.new_blob
      end

      def blob_data_lines
        blob.load_all_data!
        blob.data.lines
      end

      def current_content
        @current_content ||= blob.nil? ? [''] : blob_data_lines
      end

      def _new_content
        current_content.tap do |content|
          suggestions.each do |suggestion|
            range = line_range(suggestion)
            content[range] = suggestion.to_content
          end
        end.join
      end

      def line_range(suggestion)
        suggestion.from_line_index..suggestion.to_line_index
      end

      def for_different_file?(suggestion)
        file_path && file_path != suggestion_file_path(suggestion)
      end

      def suggestion_file_path(suggestion)
        suggestion&.diff_file&.file_path
      end

      def first_suggestion
        suggestions.first
      end

      def _file_path
        suggestion_file_path(first_suggestion)
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
