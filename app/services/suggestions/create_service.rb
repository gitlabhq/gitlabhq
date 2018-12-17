# frozen_string_literal: true

module Suggestions
  class CreateService
    def initialize(note)
      @note = note
    end

    def execute
      return unless @note.supports_suggestion?

      suggestions = Banzai::SuggestionsParser.parse(@note.note)

      # For single line suggestion we're only looking forward to
      # change the line receiving the comment. Though, in
      # https://gitlab.com/gitlab-org/gitlab-ce/issues/53310
      # we'll introduce a ```suggestion:L<x>-<y>, so this will
      # slightly change.
      comment_line = @note.position.new_line

      rows =
        suggestions.map.with_index do |suggestion, index|
          from_content = changing_lines(comment_line, comment_line)

          # The parsed suggestion doesn't have information about the correct
          # ending characters (we may have a line break, or not), so we take
          # this information from the last line being changed (last
          # characters).
          endline_chars = line_break_chars(from_content.lines.last)
          to_content = "#{suggestion}#{endline_chars}"

          {
            note_id: @note.id,
            from_content: from_content,
            to_content: to_content,
            relative_order: index
          }
        end

      rows.in_groups_of(100, false) do |rows|
        Gitlab::Database.bulk_insert('suggestions', rows)
      end
    end

    private

    def changing_lines(from_line, to_line)
      @note.diff_file.new_blob_lines_between(from_line, to_line).join
    end

    def line_break_chars(line)
      match = /\r\n|\r|\n/.match(line)
      match[0] if match
    end
  end
end
