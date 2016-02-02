module Gitlab
  module Diff
    class InlineDiff
      attr_accessor :old_line, :new_line, :offset

      def self.for_lines(lines)
        local_edit_indexes = self.find_local_edits(lines)

        inline_diffs = []

        local_edit_indexes.each do |index|
          old_index = index
          new_index = index + 1
          old_line = lines[old_index]
          new_line = lines[new_index]

          old_diffs, new_diffs = new(old_line, new_line, offset: 1).inline_diffs

          inline_diffs[old_index] = old_diffs
          inline_diffs[new_index] = new_diffs
        end

        inline_diffs
      end

      def initialize(old_line, new_line, offset: 0)
        @old_line = old_line[offset..-1]
        @new_line = new_line[offset..-1]
        @offset = offset
      end

      def inline_diffs
        # Skip inline diff if empty line was replaced with content
        return if old_line == ""

        lcp = longest_common_prefix(old_line, new_line)
        lcs = longest_common_suffix(old_line[lcp..-1], new_line[lcp..-1])

        lcp += offset
        old_length = old_line.length + offset
        new_length = new_line.length + offset

        old_diff_range = lcp..(old_length - lcs - 1)
        new_diff_range = lcp..(new_length - lcs - 1)

        old_diffs = [old_diff_range] if old_diff_range.begin <= old_diff_range.end
        new_diffs = [new_diff_range] if new_diff_range.begin <= new_diff_range.end

        [old_diffs, new_diffs]
      end

      private

      def self.find_local_edits(lines)
        line_prefixes = lines.map { |line| line.match(/\A([+-])/) ? $1 : ' ' }
        joined_line_prefixes = " #{line_prefixes.join} "

        offset = 0
        local_edit_indexes = []
        while index = joined_line_prefixes.index(" -+ ", offset)
          local_edit_indexes << index
          offset = index + 1
        end

        local_edit_indexes
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

      def longest_common_suffix(a, b)
        longest_common_prefix(a.reverse, b.reverse)
      end
    end
  end
end
