# frozen_string_literal: true

module WorkItems
  class TaskListReferenceRemovalService
    STALE_OBJECT_MESSAGE = 'Stale work item. Check lock version'

    def initialize(work_item:, task:, line_number_start:, line_number_end:, lock_version:, current_user:)
      @work_item = work_item
      @task = task
      @line_number_start = line_number_start
      @line_number_end = line_number_end
      @lock_version = lock_version
      @current_user = current_user
    end

    def execute
      return ::ServiceResponse.error(message: 'line_number_start must be greater than 0') if @line_number_start < 1
      return ::ServiceResponse.error(message: "Work item description can't be blank") if @work_item.description.blank?

      if @line_number_end < @line_number_start
        return ::ServiceResponse.error(message: 'line_number_end must be greater or equal to line_number_start')
      end

      source_lines = @work_item.description.split("\n")

      line_matches_reference = (@line_number_start..@line_number_end).any? do |line_number|
        markdown_line = source_lines[line_number - 1]

        /#{Regexp.escape(@task.to_reference)}(?!\d)/.match?(markdown_line)
      end

      unless line_matches_reference
        return ::ServiceResponse.error(
          message: "Unable to detect a task on lines #{@line_number_start}-#{@line_number_end}"
        )
      end

      remove_task_lines!(source_lines)

      ::WorkItems::UpdateService.new(
        project: @work_item.project,
        current_user: @current_user,
        params: { description: source_lines.join("\n"), lock_version: @lock_version }
      ).execute(@work_item)

      if @work_item.valid?
        ::ServiceResponse.success
      else
        ::ServiceResponse.error(message: @work_item.errors.full_messages)
      end
    rescue ActiveRecord::StaleObjectError
      ::ServiceResponse.error(message: STALE_OBJECT_MESSAGE)
    end

    private

    def remove_task_lines!(source_lines)
      source_lines.delete_if.each_with_index do |_line, index|
        index >= @line_number_start - 1 && index < @line_number_end
      end
    end
  end
end
