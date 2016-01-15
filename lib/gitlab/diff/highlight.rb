module Gitlab
  module Diff
    class Highlight
      attr_reader :diff_file

      delegate :old_path, :new_path, :old_ref, :new_ref, to: :diff_file, prefix: :diff

      def initialize(diff_file)
        @diff_file = diff_file
        @diff_lines = diff_file.diff_lines
        @raw_lines = @diff_lines.map(&:text)
      end

      def highlight
        return [] if @diff_lines.empty?

        find_inline_diffs

        process_lines

        @diff_lines
      end

      private

      def find_inline_diffs
        @inline_diffs = InlineDiff.new(@raw_lines).inline_diffs
      end

      def process_lines
        @diff_lines.each_with_index do |diff_line, i|
          # ignore highlighting for "match" lines
          next if diff_line.type == 'match'

          rich_line = highlight_line(diff_line, i)
          rich_line = mark_inline_diffs(rich_line, diff_line, i)
          diff_line.text = rich_line.html_safe
        end
      end

      def highlight_line(diff_line, index)
        line_prefix = diff_line.text.match(/\A([+-])/) ? $1 : ' '

        case diff_line.type
        when 'new', nil
          rich_line = new_lines[diff_line.new_pos - 1]
        when 'old'
          rich_line = old_lines[diff_line.old_pos - 1]
        end

        # Only update text if line is found. This will prevent
        # issues with submodules given the line only exists in diff content.
        rich_line ? line_prefix + rich_line : diff_line.text
      end

      def mark_inline_diffs(rich_line, diff_line, index)
        line_inline_diffs = @inline_diffs[index]
        return rich_line unless line_inline_diffs

        raw_line = diff_line.text
        position_mapping = map_character_positions(raw_line, rich_line)

        offset = 0
        line_inline_diffs.each do |inline_diff_range|
          inline_diff_positions = position_mapping[inline_diff_range]
          marker_ranges = collapse_ranges(inline_diff_positions)

          marker_ranges.each do |range|
            offset = insert_around_range(rich_line, range, "<span class='idiff'>", "</span>", offset)
          end
        end

        rich_line
      end

      def map_character_positions(raw_line, rich_line)
        mapping = []
        raw_pos = 0
        rich_pos = 0
        (0..raw_line.length).each do |raw_pos|
          raw_char = raw_line[raw_pos]
          rich_char = rich_line[rich_pos]

          while rich_char == '<'
            until rich_char == '>'
              rich_pos += 1
              rich_char = rich_line[rich_pos]
            end

            rich_pos += 1
            rich_char = rich_line[rich_pos]
          end

          mapping[raw_pos] = rich_pos

          rich_pos += 1
        end

        mapping
      end

      def old_lines
        @old_lines ||= Gitlab::Highlight.highlight_lines(*processing_args(:old))
      end

      def new_lines
        @new_lines ||= Gitlab::Highlight.highlight_lines(*processing_args(:new))
      end

      def collapse_ranges(positions)
        return [] if positions.empty?
        ranges = []

        start = prev = positions[0]
        range = start..prev
        positions[1..-1].each do |pos|
          if pos == prev + 1
            range = start..pos
            prev = pos
          else
            ranges << range
            start = prev = pos
            range = start..prev
          end
        end
        ranges << range

        ranges
      end

      def insert_around_range(text, range, before, after, offset = 0)
        from = range.begin
        to = range.end

        text.insert(offset + from, before)
        offset += before.length

        text.insert(offset + to + 1, after)
        offset += after.length

        offset
      end

      def processing_args(version)
        ref  = send("diff_#{version}_ref")
        path = send("diff_#{version}_path")

        [ref.project.repository, ref.id, path]
      end
    end
  end
end
