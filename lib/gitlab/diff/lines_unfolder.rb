# frozen_string_literal: true

# Given a position, calculates which Blob lines should be extracted, treated and
# injected in the current diff file lines in order to present a "unfolded" diff.
module Gitlab
  module Diff
    class LinesUnfolder
      include Gitlab::Utils::StrongMemoize

      UNFOLD_CONTEXT_SIZE = 3

      def initialize(diff_file, position)
        @diff_file = diff_file
        @blob = diff_file.old_blob
        @position = position
        @generate_top_match_line = true
        @generate_bottom_match_line = true

        # These methods update `@generate_top_match_line` and
        # `@generate_bottom_match_line`.
        @from_blob_line = calculate_from_blob_line!
        @to_blob_line = calculate_to_blob_line!
      end

      # Returns merged diff lines with required blob lines with correct
      # positions.
      def unfolded_diff_lines
        strong_memoize(:unfolded_diff_lines) do
          next unless unfold_required?

          merged_diff_with_blob_lines
        end
      end

      # Returns the extracted lines from the old blob which should be merged
      # with the current diff lines.
      def blob_lines
        strong_memoize(:blob_lines) do
          # Blob lines, unlike diffs, doesn't start with an empty space for
          # unchanged line, so the parsing and highlighting step can get fuzzy
          # without the following change.
          line_prefix = ' '
          blob_as_diff_lines = @blob.data.each_line.map { |line| "#{line_prefix}#{line}" }

          lines = Gitlab::Diff::Parser.new.parse(blob_as_diff_lines, diff_file: @diff_file).to_a

          from = from_blob_line - 1
          to = to_blob_line - 1

          lines[from..to]
        end
      end

      def unfold_required?
        strong_memoize(:unfold_required) do
          next false unless @diff_file.text?
          next false unless @position.unfoldable?
          next false if @diff_file.new_file? || @diff_file.deleted_file?
          next false unless @position.old_line
          next false unless @position.old_line.is_a?(Integer)
          # Invalid position (MR import scenario)
          next false if @position.old_line > @blob.lines.size
          next false if @diff_file.diff_lines.empty?
          next false if @diff_file.line_for_position(@position)
          next false unless unfold_line

          true
        end
      end

      private

      attr_reader :from_blob_line, :to_blob_line

      def merged_diff_with_blob_lines
        lines = @diff_file.diff_lines
        match_line = unfold_line
        insert_index = bottom? ? -1 : match_line.index

        lines -= [match_line] unless bottom?

        lines.insert(insert_index, *blob_lines_with_matches)

        # The inserted blob lines have invalid indexes, so we need
        # to reindex them.
        reindex(lines)

        lines
      end

      # Returns 'unchanged' blob lines with recalculated `old_pos` and
      # `new_pos` and the recalculated new match line (needed if we for instance
      # we unfolded once, but there are still folded lines).
      def blob_lines_with_matches
        old_pos = from_blob_line
        new_pos = from_blob_line + offset

        new_blob_lines = []

        new_blob_lines.push(top_blob_match_line) if top_blob_match_line

        blob_lines.each do |line|
          new_blob_lines << Gitlab::Diff::Line.new(line.text, line.type, nil, old_pos, new_pos,
            parent_file: @diff_file)

          old_pos += 1
          new_pos += 1
        end

        new_blob_lines.push(bottom_blob_match_line) if bottom_blob_match_line

        new_blob_lines
      end

      def reindex(lines)
        lines.each_with_index { |line, i| line.index = i }
      end

      def top_blob_match_line
        strong_memoize(:top_blob_match_line) do
          next unless @generate_top_match_line

          old_pos = from_blob_line
          new_pos = from_blob_line + offset

          build_match_line(old_pos, new_pos)
        end
      end

      def bottom_blob_match_line
        strong_memoize(:bottom_blob_match_line) do
          # The bottom line match addition is already handled on
          # Diff::File#diff_lines_for_serializer
          next if bottom?
          next unless @generate_bottom_match_line

          position = line_after_unfold_position.old_pos

          old_pos = position
          new_pos = position + offset

          build_match_line(old_pos, new_pos)
        end
      end

      def build_match_line(old_pos, new_pos)
        blob_lines_length = blob_lines.length
        old_line_ref = [old_pos, blob_lines_length].join(',')
        new_line_ref = [new_pos, blob_lines_length].join(',')
        new_match_line_str = "@@ -#{old_line_ref}+#{new_line_ref} @@"

        Gitlab::Diff::Line.new(new_match_line_str, 'match', nil, old_pos, new_pos)
      end

      # Returns the first line position that should be extracted
      # from `blob_lines`.
      def calculate_from_blob_line!
        return unless unfold_required?

        from = comment_position - UNFOLD_CONTEXT_SIZE

        prev_line_number =
          if bottom?
            last_line.old_pos
          else
            # There's no line before the match if it's in the top-most
            # position.
            line_before_unfold_position&.old_pos || 0
          end

        if from <= prev_line_number + 1
          @generate_top_match_line = false
          from = prev_line_number + 1
        end

        from
      end

      # Returns the last line position that should be extracted
      # from `blob_lines`.
      def calculate_to_blob_line!
        return unless unfold_required?

        to = comment_position + UNFOLD_CONTEXT_SIZE

        return to if bottom?

        next_line_number = line_after_unfold_position.old_pos

        if to >= next_line_number - 1
          @generate_bottom_match_line = false
          to = next_line_number - 1
        end

        to
      end

      def offset
        unfold_line.new_pos - unfold_line.old_pos
      end

      def line_before_unfold_position
        return unless index = unfold_line&.index

        @diff_file.diff_lines[index - 1] if index > 0
      end

      def line_after_unfold_position
        return unless index = unfold_line&.index

        @diff_file.diff_lines[index + 1] if index >= 0
      end

      def bottom?
        strong_memoize(:bottom) do
          @position.old_line > last_line.old_pos
        end
      end

      # Returns the line which needed to be expanded in order to send a comment
      # in `@position`.
      def unfold_line
        strong_memoize(:unfold_line) do
          next last_line if bottom?

          @diff_file.diff_lines.find do |line|
            line.old_pos > comment_position && line.type == 'match'
          end
        end
      end

      def comment_position
        @position.old_line
      end

      def last_line
        @diff_file.diff_lines.last
      end
    end
  end
end
