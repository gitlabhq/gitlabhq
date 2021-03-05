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

      def inline_diffs(project: nil)
        # Skip inline diff if empty line was replaced with content
        return if old_line == ""

        if Feature.enabled?(:improved_merge_diff_highlighting, project, default_enabled: :yaml)
          CharDiff.new(old_line, new_line).changed_ranges(offset: offset)
        else
          deprecated_diff
        end
      end

      class << self
        def for_lines(lines, project: nil)
          pair_selector = Gitlab::Diff::PairSelector.new(lines)

          inline_diffs = []

          pair_selector.each do |old_index, new_index|
            old_line = lines[old_index]
            new_line = lines[new_index]

            old_diffs, new_diffs = new(old_line, new_line, offset: 1).inline_diffs(project: project)

            inline_diffs[old_index] = old_diffs
            inline_diffs[new_index] = new_diffs
          end

          inline_diffs
        end
      end

      private

      # See: https://gitlab.com/gitlab-org/gitlab/-/issues/299884
      def deprecated_diff
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

      def longest_common_prefix(a, b) # rubocop:disable Naming/UncommunicativeMethodParamName
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

      def longest_common_suffix(a, b) # rubocop:disable Naming/UncommunicativeMethodParamName
        longest_common_prefix(a.reverse, b.reverse)
      end
    end
  end
end
