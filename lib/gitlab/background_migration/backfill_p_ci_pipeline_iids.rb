# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPCiPipelineIids < BatchedMigrationJob
      operation_name :backfill_p_ci_pipeline_iids
      feature_category :continuous_integration

      tables_to_check_for_vacuum :p_ci_pipeline_iids

      def perform
        each_sub_batch do |sub_batch|
          connection.execute(<<~SQL)
            WITH iids AS MATERIALIZED (
              #{sub_batch.select(:project_id, :iid).limit(sub_batch_size).to_sql}
            ),
            filtered_iids AS MATERIALIZED (
              SELECT project_id, iid
              FROM iids
              WHERE iid IS NOT NULL
              LIMIT #{sub_batch_size}
            )
            INSERT INTO p_ci_pipeline_iids (project_id, iid)
            SELECT project_id, iid
            FROM filtered_iids
            ON CONFLICT DO NOTHING
          SQL
        end
      end
    end
  end
end
