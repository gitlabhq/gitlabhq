# frozen_string_literal: true

module WorkItems
  module Widgets
    class Description < Base
      delegate :description, :edited?, :last_edited_at, to: :work_item

      def last_edited_by
        return unless work_item.edited?

        work_item.last_edited_by
      end
    end
  end
end
