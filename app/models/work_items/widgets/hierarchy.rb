# frozen_string_literal: true

module WorkItems
  module Widgets
    class Hierarchy < Base
      def parent
        work_item.work_item_parent
      end

      def children
        work_item.work_item_children
      end
    end
  end
end
