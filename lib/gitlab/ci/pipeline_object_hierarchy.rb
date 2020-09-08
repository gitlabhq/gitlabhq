# frozen_string_literal: true

module Gitlab
  module Ci
    class PipelineObjectHierarchy < ::Gitlab::ObjectHierarchy
      private

      def middle_table
        ::Ci::Sources::Pipeline.arel_table
      end

      def from_tables(cte)
        [objects_table, cte.table, middle_table]
      end

      def parent_id_column(_cte)
        middle_table[:source_pipeline_id]
      end

      def ancestor_conditions(cte)
        middle_table[:source_pipeline_id].eq(objects_table[:id]).and(
          middle_table[:pipeline_id].eq(cte.table[:id])
        )
      end

      def descendant_conditions(cte)
        middle_table[:pipeline_id].eq(objects_table[:id]).and(
          middle_table[:source_pipeline_id].eq(cte.table[:id])
        )
      end
    end
  end
end
