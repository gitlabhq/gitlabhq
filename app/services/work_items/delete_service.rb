# frozen_string_literal: true

module WorkItems
  class DeleteService < Issuable::DestroyService
    def execute(work_item)
      unless current_user.can?(:delete_work_item, work_item)
        return ::ServiceResponse.error(message: 'User not authorized to delete work item')
      end

      if super
        publish_event(work_item)
        ::ServiceResponse.success
      else
        ::ServiceResponse.error(message: work_item.errors.full_messages)
      end
    end

    private

    def publish_event(work_item)
      Gitlab::EventStore.publish(
        WorkItems::WorkItemDeletedEvent.new(data: {
          id: work_item.id,
          namespace_id: work_item.namespace_id,
          work_item_parent_id: work_item.work_item_parent&.id
        }.tap(&:compact_blank!))
      )
    end
  end
end
