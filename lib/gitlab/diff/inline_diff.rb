# frozen_string_literal: true

module Gitlab
  module Diff
    class InlineDiff
      attr_accessor :old_line, :new_line, :offset

      def initialize(old_line, new_line, offset: 0)
        @old_line = old_line[offset..-1]
        @new_line = new_line[offset..-1]
        @offset = offset
      end

      def inline_diffs
        # Skip inline diff if empty line was replaced with content
        return if old_line == ""

        CharDiff.new(old_line, new_line).changed_ranges(offset: offset)
      end

      # Deprecated: https://gitlab.com/gitlab-org/gitlab/-/issues/324638
      class << self
        def for_lines(lines)
          pair_selector = Gitlab::Diff::PairSelector.new(lines)

          inline_diffs = []

          pair_selector.each do |old_index, new_index|
            old_line = lines[old_index]
            new_line = lines[new_index]

            old_diffs, new_diffs = new(old_line, new_line, offset: 1).inline_diffs

            inline_diffs[old_index] = old_diffs
            inline_diffs[new_index] = new_diffs
          end

          inline_diffs
        end
      end
    end
  end
end
