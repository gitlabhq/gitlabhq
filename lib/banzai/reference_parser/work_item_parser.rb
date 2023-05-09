# frozen_string_literal: true

module Banzai
  module ReferenceParser
    class WorkItemParser < IssueParser
      self.reference_type = :work_item

      def records_for_nodes(nodes)
        @work_items_for_nodes ||= grouped_objects_for_nodes(
          nodes,
          WorkItem.all.includes(node_includes),
          self.class.data_attribute
        )
      end
    end
  end
end
