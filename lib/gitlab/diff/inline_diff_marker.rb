module Gitlab
  module Diff
    class InlineDiffMarker
      attr_accessor :raw_line, :rich_line

      def initialize(raw_line, rich_line = raw_line)
        @raw_line = raw_line
        @rich_line = rich_line
      end

      def mark(line_inline_diffs)
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

      def position_mapping
        @position_mapping ||= begin
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
        text.insert(offset + range.begin, before)
        offset += before.length

        text.insert(offset + range.end + 1, after)
        offset += after.length

        offset
      end
    end
  end
end
