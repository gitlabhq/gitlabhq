# frozen_string_literal: true

module WorkItems
  module ParentLinks
    class CreateService < IssuableLinks::CreateService
      private

      # rubocop: disable CodeReuse/ActiveRecord
      def relate_issuables(work_item)
        link = WorkItems::ParentLink.find_or_initialize_by(work_item: work_item)
        link.work_item_parent = issuable

        if link.changed? && link.save
          create_notes(work_item)
        end

        link
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def linkable_issuables(work_items)
        @linkable_issuables ||= begin
          return [] unless can?(current_user, :admin_parent_link, issuable)

          work_items.select do |work_item|
            linkable?(work_item)
          end
        end
      end

      def linkable?(work_item)
        can?(current_user, :admin_parent_link, work_item) &&
          !previous_related_issuables.include?(work_item)
      end

      def previous_related_issuables
        @related_issues ||= issuable.work_item_children.to_a
      end

      def extract_references
        params[:issuable_references]
      end

      def create_notes(work_item)
        SystemNoteService.relate_work_item(issuable, work_item, current_user)
      end

      def target_issuable_type
        'work item'
      end

      def issuables_not_found_message
        _('No matching %{issuable} found. Make sure that you are adding a valid %{issuable} ID.' %
          { issuable: target_issuable_type })
      end
    end
  end
end
