# frozen_string_literal: true

module Gitlab
  module Diff
    class PairSelector
      include Enumerable

      # Regex to find a run of deleted lines followed by the same number of added lines
      LINE_PAIRS_PATTERN = %r{
        # Runs start at the beginning of the string (the first line) or after a space (for an unchanged line)
        (?:\A|\s)

        # This matches a number of `-`s followed by the same number of `+`s through recursion
        (?<del_ins>
          -
          \g<del_ins>?
          \+
        )

        # Runs end at the end of the string (the last line) or before a space (for an unchanged line)
        (?=\s|\z)
      }x
      def initialize(lines)
        @lines = lines
      end

      # Finds pairs of old/new line pairs that represent the same line that changed
      # rubocop: disable CodeReuse/ActiveRecord
      def each
        # Prefixes of all diff lines, indicating their types
        # For example: `" - +  -+  ---+++ --+  -++"`
        line_prefixes = lines.each_with_object(+"") { |line, s| s << (line[0] || ' ') }.gsub(/[^ +-]/, ' ')

        line_prefixes.scan(LINE_PAIRS_PATTERN) do
          # For `"---+++"`, `begin_index == 0`, `end_index == 6`
          begin_index, end_index = Regexp.last_match.offset(:del_ins)

          # For `"---+++"`, `changed_line_count == 3`
          changed_line_count = (end_index - begin_index) / 2

          halfway_index = begin_index + changed_line_count
          (begin_index...halfway_index).each do |i|
            # For `"---+++"`, index 1 maps to 1 + 3 = 4
            yield [i, i + changed_line_count]
          end
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      private

      attr_reader :lines
    end
  end
end
