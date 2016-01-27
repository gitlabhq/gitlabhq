module Gitlab
  module Diff
    class InlineDiff
      attr_accessor :lines

      def initialize(lines)
        @lines = lines
      end

      def inline_diffs
        inline_diffs = []

        local_edit_indexes.each do |index|
          old_index = index
          new_index = index + 1
          old_line = @lines[old_index]
          new_line = @lines[new_index]

          # Skip inline diff if empty line was replaced with content
          next if old_line[1..-1] == ""

          # Add one, because this is based on the prefixless version
          lcp = longest_common_prefix(old_line[1..-1], new_line[1..-1]) + 1
          lcs = longest_common_suffix(old_line[lcp..-1], new_line[lcp..-1])

          old_diff_range = lcp..(old_line.length - lcs - 1)
          new_diff_range = lcp..(new_line.length - lcs - 1)

          inline_diffs[old_index] = [old_diff_range] if old_diff_range.begin <= old_diff_range.end
          inline_diffs[new_index] = [new_diff_range] if new_diff_range.begin <= new_diff_range.end
        end

        inline_diffs
      end

      private

      # Find runs of single line edits
      def local_edit_indexes
        line_prefixes = @lines.map { |line| line.match(/\A([+-])/) ? $1 : ' ' }
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
