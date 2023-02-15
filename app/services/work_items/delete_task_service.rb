# frozen_string_literal: true

module WorkItems
  class DeleteTaskService
    def initialize(work_item:, lock_version:, current_user: nil, task_params: {})
      @work_item = work_item
      @current_user = current_user
      @task_params = task_params
      @lock_version = lock_version
      @task = task_params[:task]
      @errors = []
    end

    def execute
      transaction_result = ::WorkItem.transaction do
        replacement_result = TaskListReferenceRemovalService.new(
          work_item: @work_item,
          task: @task,
          line_number_start: @task_params[:line_number_start],
          line_number_end: @task_params[:line_number_end],
          lock_version: @lock_version,
          current_user: @current_user
        ).execute

        break ::ServiceResponse.error(message: replacement_result.errors, http_status: 422) if replacement_result.error?

        delete_result = ::WorkItems::DeleteService.new(
          container: @task.project,
          current_user: @current_user
        ).execute(@task)

        if delete_result.error?
          @errors += delete_result.errors
          raise ActiveRecord::Rollback
        end

        delete_result
      end

      return transaction_result if transaction_result

      ::ServiceResponse.error(message: @errors, http_status: 422)
    end
  end
end
