# frozen_string_literal: true

module WorkItems
  module Widgets
    class Hierarchy < Base
      def parent
        return unless Feature.enabled?(:work_items, work_item.project)

        work_item.work_item_parent
      end

      def children
        return WorkItem.none unless Feature.enabled?(:work_items, work_item.project)

        work_item.work_item_children
      end
    end
  end
end
