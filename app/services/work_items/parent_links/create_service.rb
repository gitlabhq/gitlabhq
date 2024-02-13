# frozen_string_literal: true

module WorkItems
  module ParentLinks
    class CreateService < WorkItems::ParentLinks::BaseService
      private

      override :relate_issuables
      def relate_issuables(work_item)
        link = set_parent(issuable, work_item)

        link.move_to_end
        create_notes_and_resource_event(work_item, link) if link.changed? && link.save

        link
      end

      override :extract_references
      def extract_references
        params[:issuable_references]
      end

      def create_notes_and_resource_event(work_item, link)
        relate_child_note = create_notes(work_item)

        ResourceLinkEvent.create(
          user: current_user,
          work_item: link.work_item_parent,
          child_work_item: link.work_item,
          action: ResourceLinkEvent.actions[:add],
          system_note_metadata_id: relate_child_note&.system_note_metadata&.id
        )
      end
    end
  end
end

WorkItems::ParentLinks::CreateService.prepend_mod
