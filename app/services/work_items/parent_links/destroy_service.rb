# frozen_string_literal: true

module WorkItems
  module ParentLinks
    class DestroyService < IssuableLinks::DestroyService
      attr_reader :link, :current_user, :parent, :child

      def initialize(link, user)
        @link = link
        @current_user = user
        @parent = link.work_item_parent
        @child = link.work_item
      end

      private

      # TODO: Create system notes when work item's parent or children are removed
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/362213
      def create_notes
        # no-op
      end

      def not_found_message
        _('No Work Item Link found')
      end

      def permission_to_remove_relation?
        can?(current_user, :update_work_item, child) && can?(current_user, :update_work_item, parent)
      end
    end
  end
end
