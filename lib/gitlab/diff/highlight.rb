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
        @inline_diffs = []

        local_edit_indexes.each do |index|
          old_index = index
          new_index = index + 1
          old_line = @raw_lines[old_index][1..-1]
          new_line = @raw_lines[new_index][1..-1]

          # Skip inline diff if empty line was replaced with content
          next if old_line == ""

          lcp = longest_common_prefix(old_line, new_line)
          lcs = longest_common_suffix(old_line, new_line)

          old_diff_range = lcp..(old_line.length - lcs - 1)
          new_diff_range = lcp..(new_line.length - lcs - 1)

          @inline_diffs[old_index] = old_diff_range if old_diff_range.begin <= old_diff_range.end
          @inline_diffs[new_index] = new_diff_range if new_diff_range.begin <= new_diff_range.end
        end
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
        line_prefix = line_prefixes[index]

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
        inline_diff = @inline_diffs[index]
        return rich_line unless inline_diff

        raw_line = diff_line.text

        # Based on the prefixless versions
        from = inline_diff.begin + 1
        to = inline_diff.end + 1

        position_mapping = map_character_positions(raw_line, rich_line)
        inline_diff_positions = position_mapping[from..to]
        marker_ranges = collapse_ranges(inline_diff_positions)

        offset = 0
        marker_ranges.each do |range|
          offset = insert_around_range(rich_line, range, "<span class='idiff'>", "</span>", offset)
        end

        rich_line
      end

      def line_prefixes
        @line_prefixes ||= @raw_lines.map { |line| line.match(/\A([+-])/) ? $1 : ' ' }
      end

      def local_edit_indexes
        @local_edit_indexes ||= begin
          joined_line_prefixes = " #{line_prefixes.join} "

          offset = 0
          local_edit_indexes = []
          while index = joined_line_prefixes.index(" -+ ", offset)
            local_edit_indexes << index
            offset = index + 1
          end

          local_edit_indexes
        end
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

      def longest_common_suffix(a, b)
        longest_common_prefix(a.reverse, b.reverse)
      end

      def longest_common_prefix(a, b)
        max_length = [a.length, b.length].max

        length = 0
        (0..max_length - 1).each do |pos|
          old_char = a[pos]
          new_char = b[pos]

          break if old_char != new_char
          length += 1
        end

        length
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

      private

      def processing_args(version)
        ref  = send("diff_#{version}_ref")
        path = send("diff_#{version}_path")

        [ref.project.repository, ref.id, path]
      end

    end
  end
end
