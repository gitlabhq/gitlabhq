# frozen_string_literal: true

module WorkItems
  class DeleteService < Issuable::DestroyService
    def execute(work_item)
      unless current_user.can?(:delete_work_item, work_item)
        return ::ServiceResponse.error(message: 'User not authorized to delete work item')
      end

      if super
        ::ServiceResponse.success
      else
        ::ServiceResponse.error(message: work_item.errors.full_messages)
      end
    end
  end
end
