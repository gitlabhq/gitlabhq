# frozen_string_literal: true

module Gitlab
  module Ci
    class ProcessableObjectHierarchy < ::Gitlab::ObjectHierarchy
      private

      def middle_table
        ::Ci::BuildNeed.arel_table
      end

      def from_tables(cte)
        [objects_table, cte.table, middle_table]
      end

      def parent_id_column(_cte)
        middle_table[:name]
      end

      def ancestor_conditions(cte)
        middle_table[:name].eq(objects_table[:name]).and(
          middle_table[:build_id].eq(cte.table[:id])
        )
      end

      def descendant_conditions(cte)
        middle_table[:build_id].eq(objects_table[:id]).and(
          middle_table[:name].eq(cte.table[:name])
        )
      end
    end
  end
end
