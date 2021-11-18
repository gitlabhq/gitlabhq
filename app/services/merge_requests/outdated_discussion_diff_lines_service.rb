# frozen_string_literal: true

module MergeRequests
  class OutdatedDiscussionDiffLinesService
    include Gitlab::Utils::StrongMemoize

    attr_reader :project, :note

    OVERFLOW_LINES_COUNT = 2

    def initialize(project:, note:)
      @project = project
      @note = note
    end

    def execute
      end_position = position.line_range["end"]
      diff_line_index = diff_lines.find_index do |l|
        if end_position["new_line"]
          l.new_line == end_position["new_line"]
        elsif end_position["old_line"]
          l.old_line == end_position["old_line"]
        end
      end
      initial_line_index = [diff_line_index - OVERFLOW_LINES_COUNT, 0].max
      last_line_index = [diff_line_index + OVERFLOW_LINES_COUNT, diff_lines.length].min

      prev_lines = []

      diff_lines[initial_line_index..last_line_index].each do |line|
        if line.meta?
          prev_lines.clear
        else
          prev_lines << line
        end
      end

      prev_lines
    end

    private

    def position
      note.change_position
    end

    def repository
      project.repository
    end

    def diff_file
      position.diff_file(repository)
    end

    def diff_lines
      strong_memoize(:diff_lines) do
        diff_file.highlighted_diff_lines
      end
    end
  end
end
