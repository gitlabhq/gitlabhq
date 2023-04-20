# frozen_string_literal: true

module WorkItems
  module ParentLinks
    class CreateService < WorkItems::ParentLinks::BaseService
      private

      override :relate_issuables
      def relate_issuables(work_item)
        link = set_parent(issuable, work_item)

        link.move_to_end

        if link.changed? && link.save
          relate_child_note = create_notes(work_item)

          ResourceLinkEvent.create(
            user: current_user,
            work_item: link.work_item_parent,
            child_work_item: link.work_item,
            action: ResourceLinkEvent.actions[:add],
            system_note_metadata_id: relate_child_note&.system_note_metadata&.id
          )
        end

        link
      end

      override :extract_references
      def extract_references
        params[:issuable_references]
      end
    end
  end
end
