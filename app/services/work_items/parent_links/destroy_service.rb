# frozen_string_literal: true

module WorkItems
  module ParentLinks
    class DestroyService < IssuableLinks::DestroyService
      extend ::Gitlab::Utils::Override

      attr_reader :link, :current_user, :parent, :child

      def initialize(link, user, params = {})
        @link = link
        @current_user = user
        @params = params
        @parent = link.work_item_parent
        @child = link.work_item
      end

      private

      def create_notes
        unrelate_note = SystemNoteService.unrelate_work_item(parent, child, current_user)

        ResourceLinkEvent.create(
          user: @current_user,
          work_item: @link.work_item_parent,
          child_work_item: @link.work_item,
          action: ResourceLinkEvent.actions[:remove],
          system_note_metadata_id: unrelate_note&.system_note_metadata&.id
        )
      end

      def not_found_message
        _('No Work Item Link found')
      end

      def permission_to_remove_relation?
        can?(current_user, :admin_parent_link, child) && can?(current_user, :admin_parent_link, parent)
      end

      override :after_destroy
      def after_destroy
        super

        GraphqlTriggers.work_item_updated(@link.work_item_parent)
      end
    end
  end
end

WorkItems::ParentLinks::DestroyService.prepend_mod
