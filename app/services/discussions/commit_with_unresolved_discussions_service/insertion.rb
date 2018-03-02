module Discussions
  class CommitWithUnresolvedDiscussionsService
    class Insertion
      include Comparable

      attr_accessor :discussion, :override_preceding_lines

      def initialize(discussion)
        @discussion = discussion
      end

      def insert(target_lines, commenter, offset: 0)
        line_index = line + offset

        insertion_lines = text(target_lines[0..line_index-1], commenter).lines
        target_lines.insert(line_index, *insertion_lines)

        insertion_lines.length
      end

      def line
        position.removed? ? discussion.diff_line.new_pos - 1 : position.new_line
      end

      def path
        position.file_path
      end

      def <=>(other)
        sort_key <=> other.sort_key
      end

      def sort_key
        [
          line,
          # Comments related to a preceding line should show up before comments
          # related to a deleted
          # line at the same location.
          position.removed? ? 1 : 0,
          discussion.created_at
        ]
      end

      private

      def text(preceding_lines, commenter)
        text = base_text.dup

        text = commenter.apply(base_text) if commenter

        # We determine the indentation level of the insertion based the actual
        # preceding lines, or the original preceding lines in case of deletion.
        preceding_lines = removed_diff_lines if position.removed?

        text.gsub!(/^/, indentation(preceding_lines)) if preceding_lines

        text
      end

      def base_text
        sections = []

        # When the discussion is on a deleted line, we include the preceding 5
        # deleted lines in the comment.
        sections << removed_lines_text if position.removed?

        discussion.notes.each_with_index do |note, i|
          sections << note_text(note, started: i == 0)
        end

        text = sections.join("\n\n")

        text << "\n" unless text.end_with?("\n")
        text
      end

      def position
        discussion.position
      end

      def removed_diff_lines
        @removed_diff_lines ||=
          discussion
            .truncated_diff_lines(highlight: false)
            .reverse[0, 5]
            .take_while(&:removed?)
            .reverse
            .map { |l| l.text[1..-1] } # Drop the - prefixes
      end

      def removed_lines_text
        heading = "Old #{"line".pluralize(removed_diff_lines.count)}:"
        indented_removed_lines = removed_diff_lines.join("\n").strip_heredoc.gsub(/^/, '  ')

        [heading, indented_removed_lines].join("\n")
      end

      def note_text(note, started: false)
        byline = "FIXME: #{note.author.name} (#{note.author.to_reference}) "
        byline << (started ? "started a discussion on the preceding line:" : "commented:")
        byline << " (Resolved by #{note.resolved_by.try(:name)})" if note.resolved?

        comment = note.note.gsub(/^/, '  ')

        [byline, comment].join("\n")
      end

      def indentation(preceding_lines)
        # Find closest preceding non-blank line
        preceding_line = preceding_lines.reverse.find(&:present?)
        # Fall back on preceding line
        preceding_line ||= preceding_lines.last

        return unless preceding_line

        preceding_line[/\A[\t ]*/]
      end
    end
  end
end
