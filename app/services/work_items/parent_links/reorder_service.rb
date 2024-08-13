# frozen_string_literal: true

module WorkItems
  module ParentLinks
    class ReorderService < WorkItems::ParentLinks::BaseService
      private

      override :relate_issuables
      def relate_issuables(work_item)
        notes_are_expected = work_item.work_item_parent != issuable
        link = set_parent(issuable, work_item)

        if reorder(link, params[:adjacent_work_item], params[:relative_position])
          create_notes(work_item) if notes_are_expected
          # When the hierarchy is changed from the children list,
          # we have to trigger the update on the parent to update the view
          GraphqlTriggers.work_item_updated(issuable)
        end

        link
      end

      def reorder(link, adjacent_work_item, relative_position)
        WorkItems::ParentLink.move_nulls_to_end(RelativePositioning.mover.context(link).relative_siblings)

        move_link(link, adjacent_work_item, relative_position)
      end

      # overriden in EE
      def move_link(link, adjacent_work_item, relative_position)
        if relative_position
          link.move_before(adjacent_work_item.parent_link) if relative_position == 'BEFORE'
          link.move_after(adjacent_work_item.parent_link) if relative_position == 'AFTER'
        elsif link.changes.include?(:work_item_parent_id)
          # position item at the start of the list if parent changed and relative_position is not provided
          link.move_to_start
        end

        link.save
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
