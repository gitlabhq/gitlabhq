# frozen_string_literal: true

module Gitlab
  module Diff
    class InlineDiff
      attr_accessor :old_line, :new_line, :offset

      def initialize(old_line, new_line, offset: 0)
        @old_line = old_line[offset..]
        @new_line = new_line[offset..]
        @offset = offset
      end

      def inline_diffs
        # Skip inline diff if empty line was replaced with content
        return if old_line == ""

        CharDiff.new(old_line, new_line).changed_ranges(offset: offset)
      end
    end
  end
end
