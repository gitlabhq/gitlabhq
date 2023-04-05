# frozen_string_literal: true

module WorkItems
  module ParentLinks
    class CreateService < WorkItems::ParentLinks::BaseService
      private

      override :relate_issuables
      def relate_issuables(work_item)
        link = set_parent(issuable, work_item)

        link.move_to_end
        create_notes(work_item) if link.changed? && link.save

        link
      end

      override :extract_references
      def extract_references
        params[:issuable_references]
      end
    end
  end
end
