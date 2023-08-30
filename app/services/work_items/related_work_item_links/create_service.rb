# frozen_string_literal: true

module WorkItems
  module RelatedWorkItemLinks
    class CreateService < IssuableLinks::CreateService
      extend ::Gitlab::Utils::Override

      def execute
        return error(_('No matching work item found.'), 404) unless can?(current_user, :admin_work_item_link, issuable)

        response = super

        if response[:status] == :success
          response[:message] = format(
            _('Successfully linked ID(s): %{item_ids}.'),
            item_ids: linked_ids(response[:created_references]).to_sentence
          )
        end

        response
      end

      def linkable_issuables(work_items)
        @linkable_issuables ||= work_items.select { |work_item| can_link_item?(work_item) }
      end

      def previous_related_issuables
        @related_issues ||= issuable.linked_work_items(authorize: false).to_a
      end

      private

      def link_class
        WorkItems::RelatedWorkItemLink
      end

      def can_link_item?(work_item)
        return true if can?(current_user, :admin_work_item_link, work_item)

        @errors << format(
          _("Item with ID: %{id} cannot be added. You don't have permission to perform this action."),
          id: work_item.id
        )

        false
      end

      def linked_ids(created_links)
        created_links.collect(&:target_id)
      end

      override :issuables_already_assigned_message
      def issuables_already_assigned_message
        _('Work items are already linked')
      end

      override :issuables_not_found_message
      def issuables_not_found_message
        _('No matching work item found. Make sure you are adding a valid ID and you have access to the item.')
      end
    end
  end
end

WorkItems::RelatedWorkItemLinks::CreateService.prepend_mod_with('WorkItems::RelatedWorkItemLinks::CreateService')
