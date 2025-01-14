# frozen_string_literal: true

module WorkItems
  module ParentLinks
    class CreateService < WorkItems::ParentLinks::BaseService
      private

      override :relate_issuables
      def relate_issuables(work_item)
        link = set_parent(issuable, work_item)

        # It's possible to force the relative_position. This is for example used when importing parent links from
        # legacy epics.
        if params[:relative_position]
          link.relative_position = params[:relative_position]
        else
          link.move_to_start
        end

        create_notes_and_resource_event(work_item, link) if link.save

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

      override :after_create_for
      def after_create_for(link)
        super

        GraphqlTriggers.work_item_updated(link.work_item_parent)
      end
    end
  end
end

WorkItems::ParentLinks::CreateService.prepend_mod
