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
      line_position = position.line_range["end"] || position.line_range["start"]
      found_line = false
      diff_line_index = -1
      diff_lines.each_with_index do |l, i|
        if found_line
          if !l.type
            break
          elsif l.type == 'new'
            diff_line_index = i
            break
          end
        else
          # Find the old line
          found_line = l.old_line == line_position["new_line"]
        end

        diff_line_index = i
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
