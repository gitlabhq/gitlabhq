# frozen_string_literal: true

module Gitlab
  module WorkItems
    class WorkItemHierarchy < ObjectHierarchy
      extend ::Gitlab::Utils::Override

      private

      def middle_table
        ::WorkItems::ParentLink.arel_table
      end

      def from_tables(cte)
        [objects_table, cte.table, middle_table]
      end

      override :parent_id_column
      def parent_id_column(cte)
        middle_table[:work_item_parent_id]
      end

      override :ancestor_conditions
      def ancestor_conditions(cte)
        conditions = middle_table[:work_item_parent_id].eq(objects_table[:id]).and(
          middle_table[:work_item_id].eq(cte.table[:id])
        )

        with_type_filter(conditions, cte)
      end

      override :descendant_conditions
      def descendant_conditions(cte)
        conditions = middle_table[:work_item_id].eq(objects_table[:id]).and(
          middle_table[:work_item_parent_id].eq(cte.table[:id])
        )

        with_type_filter(conditions, cte)
      end

      def with_type_filter(conditions, cte)
        return conditions unless options[:same_type]

        type_column_name = :"#{::Gitlab::Issues::TypeAssociationGetter.call}_id"

        conditions.and(objects_table[type_column_name].eq(cte.table[type_column_name]))
      end
    end
  end
end
