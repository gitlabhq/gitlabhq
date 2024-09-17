# frozen_string_literal: true

module WorkItems
  module Callbacks
    class LinkedItems < Base
      def after_save_commit
        return unless params.present? && params.key?(:work_items_ids)
        return unless has_permission?(:set_work_item_metadata)

        execute_linked_items_service(params[:work_items_ids], params[:link_type])
      end

      private

      def execute_linked_items_service(item_ids, link_type)
        items_to_link = WorkItem.id_in(item_ids)

        result = ::WorkItems::RelatedWorkItemLinks::CreateService
                  .new(work_item, current_user, { target_issuable: items_to_link, link_type: link_type })
                  .execute

        raise_error(result[:message]) if result[:status] == :error
      end
    end
  end
end
