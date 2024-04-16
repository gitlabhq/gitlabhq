# frozen_string_literal: true

module WorkItems
  module ParentLinks
    class ReorderService < WorkItems::ParentLinks::BaseService
      private

      override :relate_issuables
      def relate_issuables(work_item)
        notes_are_expected = work_item.work_item_parent != issuable
        link = set_parent(issuable, work_item)
        reorder(link, params[:adjacent_work_item], params[:relative_position])

        create_notes(work_item) if link.save && notes_are_expected

        link
      end

      def reorder(link, adjacent_work_item, relative_position)
        WorkItems::ParentLink.move_nulls_to_end(RelativePositioning.mover.context(link).relative_siblings)

        adjacent_parent_link = adjacent_work_item.parent_link
        # if issuable is an epic, we can create the missing parent link between epic work item and adjacent_work_item
        if adjacent_parent_link.blank? && adjacent_work_item.synced_epic
          adjacent_parent_link = set_parent(issuable, adjacent_work_item)
          adjacent_parent_link.relative_position = adjacent_work_item.synced_epic.relative_position
          adjacent_parent_link.save!
        end

        return unless adjacent_parent_link

        link.move_before(adjacent_parent_link) if relative_position == 'BEFORE'
        link.move_after(adjacent_parent_link) if relative_position == 'AFTER'
      end

      override :render_conflict_error?
      def render_conflict_error?
        return false if params[:adjacent_work_item] && params[:relative_position]

        super
      end

      override :linkable?
      def linkable?(work_item)
        can_admin_link?(work_item)
      end
    end
  end
end

WorkItems::ParentLinks::ReorderService.prepend_mod
