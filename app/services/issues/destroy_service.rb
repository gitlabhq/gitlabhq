# frozen_string_literal: true

module Issues
  class DestroyService < Issuable::DestroyService
    private

    def before_destroy(issuable)
      @work_item_parent_id = WorkItems::ParentLink.for_children(issuable.id).first&.work_item_parent_id

      super
    end

    def after_destroy(issuable)
      super

      event = WorkItems::WorkItemDeletedEvent.new(data: {
        id: issuable.id,
        namespace_id: issuable.namespace_id,
        previous_work_item_parent_id: @work_item_parent_id
      }.tap(&:compact_blank!))

      issuable.run_after_commit_or_now do
        Gitlab::EventStore.publish(event)
      end
    end
  end
end
