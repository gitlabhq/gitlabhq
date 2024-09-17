# frozen_string_literal: true

module Gitlab
  module Diff
    class MergeRequestSuggestion
      include Gitlab::Utils::StrongMemoize

      TargetLineNotFound = Class.new(StandardError)

      SUGGESTION_HEADER = "```suggestion:"
      SUGGESTION_FOOTER = "```"

      def initialize(diff, path, merge_request)
        @diff = diff
        @path = path
        @merge_request = merge_request
        @project = merge_request.project
      end

      def note_attributes_hash
        {
          position: position,
          note: suggestion,
          type: "DiffNote",
          noteable_type: MergeRequest,
          noteable_id: @merge_request.id
        }
      end

      private

      def diff_lines
        parsed_lines = Gitlab::Diff::Parser.new.parse(@diff.lines)
        lines = []

        parsed_lines.each_with_index do |line, index|
          next if line.text.start_with?("diff --git") && index == 0
          next if line.type == 'match'

          lines << line
        end

        lines
      end
      strong_memoize_attr :diff_lines

      def suggestion_start_line
        diff_lines.first.old_pos
      end

      def suggestion_last_removed_line
        diff_lines.reverse.find(&:removed?).old_pos
      end
      strong_memoize_attr :suggestion_last_removed_line

      def suggestion_line_count
        # We subtract the `suggestion_start_line` from `suggestion_last_removed_line` since we'll be
        # creating the diff note on the merge_request diff line corresponding to the `suggestion_last_removed_line`.
        # This is to ensure that the suggestion will only replace the lines that
        # also exist in the supplied diff patch.
        suggestion_last_removed_line - suggestion_start_line
      end

      def suggestion_last_line
        diff_lines.last.old_pos
      end

      def suggestion_last_added_line
        diff_lines.reverse.find(&:added?).new_pos
      end

      def remainder_suggestion_line_count
        # We subtract the position of last added line from the last line in
        # supplied diff patch so we can get the rest of the lines that will need
        # to be replaced by the suggestion.
        #
        # This is needed so we can include the lines that need to be replaced
        # below the line the diff note with suggestion is being posted on.
        suggestion_last_line - suggestion_last_added_line
      end

      def suggestion_target_line
        # We use the `suggestion_last_removed_line` as the line where we will create the note
        # so the suggestion will show right on the last line that the suggestion will
        # replace. This allows us to show the diff of the lines going to be replaced
        # in the `Overview` tab.
        #
        # We get the `suggestion_last_removed_line` and find the corresponding line in
        # the merge request diff of the specific file being suggested on.
        #
        # This is to ensure we can create the note on the correct line in the merge_request diff.
        raise TargetLineNotFound if merge_request_diff_file.nil?

        merge_request_diff_file.diff_lines.find { |line| line.new_line == suggestion_last_removed_line }
      end
      strong_memoize_attr :suggestion_target_line

      def suggestion_meta
        "-#{suggestion_line_count}+#{remainder_suggestion_line_count}"
      end

      def suggestion
        array = [SUGGESTION_HEADER + suggestion_meta]

        diff_lines.each do |line|
          array << line.text(prefix: false) if line.added? || line.unchanged?
        end

        array << SUGGESTION_FOOTER
        array.join("\n")
      end

      def latest_merge_request_diff
        @merge_request.latest_merge_request_diff
      end
      strong_memoize_attr :latest_merge_request_diff

      def position
        {
          position_type: "text",
          old_path: @path,
          new_path: @path,
          base_sha: latest_merge_request_diff.base_commit_sha,
          head_sha: latest_merge_request_diff.head_commit_sha,
          start_sha: latest_merge_request_diff.start_commit_sha,
          old_line: (suggestion_target_line&.old_pos unless suggestion_target_line.added?),
          new_line: (suggestion_target_line&.new_pos unless suggestion_target_line.removed?),
          ignore_whitespace_change: false
        }
      end

      def merge_request_diff_file
        diff_options = {
          paths: [@path],
          expanded: true,
          include_stats: false,
          ignore_whitespace_change: false
        }

        @merge_request.diffs(diff_options).diff_files.first
      end
      strong_memoize_attr :merge_request_diff_file
    end
  end
end
