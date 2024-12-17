# frozen_string_literal: true

module WorkItems
  class CreateFromTaskService
    def initialize(work_item:, perform_spam_check: true, current_user: nil, work_item_params: {})
      @work_item = work_item
      @current_user = current_user
      @work_item_params = work_item_params
      @perform_spam_check = perform_spam_check
      @errors = []
    end

    def execute
      transaction_result = ApplicationRecord.transaction do
        create_and_link_result = CreateAndLinkService.new(
          project: @work_item.project,
          current_user: @current_user,
          params: @work_item_params.slice(:title, :work_item_type_id, :work_item_type),
          perform_spam_check: @perform_spam_check,
          link_params: { parent_work_item: @work_item }
        ).execute

        if create_and_link_result.error?
          @errors += create_and_link_result.errors
          raise ActiveRecord::Rollback
        end

        replacement_result = TaskListReferenceReplacementService.new(
          work_item: @work_item,
          current_user: @current_user,
          work_item_reference: create_and_link_result[:work_item].to_reference,
          line_number_start: @work_item_params[:line_number_start],
          line_number_end: @work_item_params[:line_number_end],
          title: @work_item_params[:title],
          lock_version: @work_item_params[:lock_version]
        ).execute

        if replacement_result.error?
          @errors += replacement_result.errors
          raise ActiveRecord::Rollback
        end

        create_and_link_result
      end

      return transaction_result if transaction_result

      ::ServiceResponse.error(message: @errors, http_status: 422)
    end
  end
end
