# frozen_string_literal: true

module WorkItems
  class TaskListReferenceReplacementService
    STALE_OBJECT_MESSAGE = 'Stale work item. Check lock version'

    def initialize(work_item:, current_user:, work_item_reference:, line_number_start:, line_number_end:, title:, lock_version:)
      @work_item = work_item
      @current_user = current_user
      @work_item_reference = work_item_reference
      @line_number_start = line_number_start
      @line_number_end = line_number_end
      @title = title
      @lock_version = lock_version
    end

    def execute
      return ::ServiceResponse.error(message: STALE_OBJECT_MESSAGE) if @work_item.lock_version > @lock_version
      return ::ServiceResponse.error(message: 'line_number_start must be greater than 0') if @line_number_start < 1
      return ::ServiceResponse.error(message: 'line_number_end must be greater or equal to line_number_start') if @line_number_end < @line_number_start
      return ::ServiceResponse.error(message: "Work item description can't be blank") if @work_item.description.blank?

      source_lines = @work_item.description.split("\n")
      markdown_task_first_line = source_lines[@line_number_start - 1]
      task_line = Taskable::ITEM_PATTERN.match(markdown_task_first_line)

      return ::ServiceResponse.error(message: "Unable to detect a task on line #{@line_number_start}") unless task_line

      captures = task_line.captures

      markdown_task_first_line.sub!(Taskable::ITEM_PATTERN, "#{captures[0]} #{captures[1]} #{@work_item_reference}+")

      source_lines[@line_number_start - 1] = markdown_task_first_line
      remove_additional_lines!(source_lines)

      ::WorkItems::UpdateService.new(
        container: @work_item.project,
        current_user: @current_user,
        params: { description: source_lines.join("\n"), lock_version: @lock_version }
      ).execute(@work_item)

      ::ServiceResponse.success
    rescue ActiveRecord::StaleObjectError
      ::ServiceResponse.error(message: STALE_OBJECT_MESSAGE)
    end

    private

    def remove_additional_lines!(source_lines)
      return if @line_number_end <= @line_number_start

      source_lines.delete_if.each_with_index do |_line, index|
        index >= @line_number_start && index < @line_number_end
      end
    end
  end
end
