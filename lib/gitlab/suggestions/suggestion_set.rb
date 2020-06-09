# frozen_string_literal: true

module Gitlab
  module Suggestions
    class SuggestionSet
      attr_reader :suggestions

      def initialize(suggestions)
        @suggestions = suggestions
      end

      def project
        first_suggestion.project
      end

      def branch
        first_suggestion.branch
      end

      def valid?
        error_message.nil?
      end

      def error_message
        @error_message ||= _error_message
      end

      def actions
        @actions ||= suggestions_per_file.map do |file_path, file_suggestion|
          {
            action: 'update',
            file_path: file_path,
            content: file_suggestion.new_content
          }
        end
      end

      def file_paths
        @file_paths ||= suggestions.map(&:file_path).uniq
      end

      private

      def first_suggestion
        suggestions.first
      end

      def suggestions_per_file
        @suggestions_per_file ||= _suggestions_per_file
      end

      def _suggestions_per_file
        suggestions.each_with_object({}) do |suggestion, result|
          file_path = suggestion.diff_file.file_path
          file_suggestion = result[file_path] ||= FileSuggestion.new
          file_suggestion.add_suggestion(suggestion)
        end
      end

      def file_suggestions
        suggestions_per_file.values
      end

      def first_file_suggestion
        file_suggestions.first
      end

      def _error_message
        suggestions.each do |suggestion|
          message = error_for_suggestion(suggestion)

          return message if message
        end

        has_line_conflict = file_suggestions.any? do |file_suggestion|
          file_suggestion.line_conflict?
        end

        if has_line_conflict
          return _('Suggestions are not applicable as their lines cannot overlap.')
        end

        nil
      end

      def error_for_suggestion(suggestion)
        unless suggestion.diff_file
          return _('A file was not found.')
        end

        unless on_same_branch?(suggestion)
          return _('Suggestions must all be on the same branch.')
        end

        unless suggestion.appliable?(cached: false)
          return _('A suggestion is not applicable.')
        end

        unless latest_source_head?(suggestion)
          return _('A file has been changed.')
        end

        nil
      end

      def on_same_branch?(suggestion)
        branch == suggestion.branch
      end

      # Checks whether the latest source branch HEAD matches with
      # the position HEAD we're using to update the file content. Since
      # the persisted HEAD is updated async (for MergeRequest),
      # it's more consistent to fetch this data directly from the
      # repository.
      def latest_source_head?(suggestion)
        suggestion.position.head_sha == suggestion.noteable.source_branch_sha
      end
    end
  end
end
