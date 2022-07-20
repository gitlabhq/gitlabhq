# frozen_string_literal: true

module WorkItems
  module Widgets
    class Hierarchy < Base
      def parent
        return unless work_item.project.work_items_feature_flag_enabled?

        work_item.work_item_parent
      end

      def children
        return WorkItem.none unless work_item.project.work_items_feature_flag_enabled?

        work_item.work_item_children
      end
    end
  end
end
