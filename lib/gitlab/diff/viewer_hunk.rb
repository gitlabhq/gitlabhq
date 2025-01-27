# frozen_string_literal: true

module Gitlab
  module Diff
    class ViewerHunk
      attr_reader :header
      attr_accessor :lines

      def self.init_from_diff_lines(diff_lines)
        return [] if diff_lines.empty?

        hunks = []
        current_hunk = nil
        line_count = diff_lines.size

        diff_lines.each_with_index do |line, index|
          current_line = line
          is_match = current_line.type == 'match'

          if is_match || current_hunk.nil?
            if is_match
              previous_line_pos = hunks.last&.lines&.last&.old_pos

              next_line = index < line_count - 1 ? diff_lines[index + 1] : nil
              next_line_pos = next_line&.old_pos

              current_hunk = new(
                lines: [],
                header: ViewerHunkHeader.new(current_line, previous_line_pos, next_line_pos)
              )
            else
              current_hunk = new(lines: [line])
            end

            hunks << current_hunk
          else
            current_hunk.lines << line
          end
        end

        hunks
      end

      def self.init_from_expanded_lines(diff_lines, bottom, closest_line_number)
        return if diff_lines.empty?

        match_lines, non_match_lines = diff_lines.partition { |line| line.type == 'match' }
        return if non_match_lines.empty?

        first_pos = non_match_lines.first.old_pos
        last_pos = non_match_lines.last.old_pos

        closest_line_number = 0 unless valid_closest_line_number?(bottom, closest_line_number, first_pos, last_pos)

        header = if match_lines.first
                   start_line, end_line = bottom ? [last_pos, closest_line_number] : [closest_line_number, first_pos]
                   ViewerHunkHeader.new(match_lines.first, start_line, end_line)
                 end

        create_viewer_hunks(non_match_lines, header, bottom)
      end

      def self.create_viewer_hunks(non_match_lines, header, bottom)
        if bottom
          [new(lines: non_match_lines), new(lines: nil, header: header)]
        else
          [new(lines: non_match_lines, header: header)]
        end
      end
      private_class_method :create_viewer_hunks

      def self.valid_closest_line_number?(bottom, closest_line_number, first_pos, last_pos)
        return false if closest_line_number.nil? || closest_line_number < 0

        closest_line_number == 0 || (

          if bottom
            last_pos < closest_line_number
          else
            closest_line_number < first_pos
          end

        )
      end
      private_class_method :valid_closest_line_number?

      def initialize(lines: [], header: nil)
        @lines = lines
        @header = header
      end

      def parallel_lines
        ::Gitlab::Diff::ParallelDiff.parallelize(lines)
      end
    end

    class ViewerHunkHeader
      attr_reader :line

      MAX_EXPANDABLE_LINES = 20

      def initialize(line, previous_line_pos, next_line_pos)
        @line = line
        @previous_line_pos = previous_line_pos
        @next_line_pos = next_line_pos
      end

      def text
        @line.text
      end

      def expand_directions
        return [:both] if (1...MAX_EXPANDABLE_LINES).cover?(line_count_between)

        directions = []
        directions << :down if @previous_line_pos&.positive?
        directions << :up if @next_line_pos&.positive?
        directions
      end

      private

      def line_count_between
        return 0 if invalid_pos?(@previous_line_pos) || invalid_pos?(@next_line_pos)

        @next_line_pos - @previous_line_pos
      end

      def invalid_pos?(pos)
        pos.nil? || pos == 0
      end
    end
  end
end
