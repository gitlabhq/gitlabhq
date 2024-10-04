# frozen_string_literal: true

module Gitlab
  module Diff
    class ViewerHunk
      MAX_EXPANDABLE_LINES = 20

      attr_reader :header, :prev
      attr_accessor :lines

      def self.init_from_diff_lines(diff_lines)
        return [] if diff_lines.empty?

        hunks = []
        current_hunk = nil

        diff_lines.each do |line|
          current_line = line
          is_match = current_line.type == 'match'

          if is_match || current_hunk.nil?
            current_hunk = new(
              header: is_match ? current_line : nil,
              lines: is_match ? [] : [line],
              prev: hunks.last
            )
            hunks << current_hunk
          else
            current_hunk.lines << line
          end
        end

        hunks
      end

      def initialize(lines:, header: nil, prev: nil)
        @header = header
        @lines = lines
        @prev = prev
      end

      def expand_directions
        return [:both] if line_count_between != 0 && line_count_between < MAX_EXPANDABLE_LINES

        directions = []
        directions << :down if lines.empty? || !!prev
        directions << :up unless header&.index.nil?
        directions
      end

      def parallel_lines
        ::Gitlab::Diff::ParallelDiff.parallelize(lines)
      end

      def header_text
        @header.text
      end

      private

      def line_count_between
        return 0 if !prev || lines.empty? || prev.lines.empty?

        lines.first.old_pos - prev.lines.last.old_pos
      end
    end
  end
end
