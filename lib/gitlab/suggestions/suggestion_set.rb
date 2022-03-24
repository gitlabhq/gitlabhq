# frozen_string_literal: true

module Gitlab
  module Suggestions
    class SuggestionSet
      attr_reader :suggestions

      def initialize(suggestions)
        @suggestions = suggestions
      end

      def source_project
        first_suggestion.source_project
      end

      def target_project
        first_suggestion.target_project
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
        @actions ||= suggestions_per_file.map do |file_suggestion|
          {
            action: 'update',
            file_path: file_suggestion.file_path,
            content: file_suggestion.new_content
          }
        end
      end

      def file_paths
        @file_paths ||= suggestions.map(&:file_path).uniq
      end

      def authors
        suggestions.map { |suggestion| suggestion.note.author }.uniq
      end

      private

      def first_suggestion
        suggestions.first
      end

      def suggestions_per_file
        @suggestions_per_file ||= _suggestions_per_file
      end

      def _suggestions_per_file
        suggestions
          .group_by { |suggestion| suggestion.diff_file.file_path }
          .map { |file_path, group| FileSuggestion.new(file_path, group) }
      end

      def _error_message
        suggestions.each do |suggestion|
          message = error_for_suggestion(suggestion)

          return message if message
        end

        has_line_conflict = suggestions_per_file.any? do |file_suggestion|
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
          return suggestion.inapplicable_reason(cached: false)
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
