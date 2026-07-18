# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPackagesHelmMetadataCacheStatesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_packages_helm_metadata_cache_states_project_id
      feature_category :geo_replication

      def perform
        # Some parent packages_helm_metadata_caches rows reference a project that
        # no longer exists: their project was deleted but the loose foreign key
        # cleanup never ran, so the cache was neither destroyed nor nullified.
        # Their child states cannot be backfilled (the value would violate
        # fk_2902beee34, project_id -> projects.id). We delete the orphaned parent
        # cache, which cascades to the child state via fk_rails_281379b415
        # (ON DELETE CASCADE). Deleting only the child state would not work: Geo
        # recreates it (VerifiableModel#save_verification_details and
        # Geo::VerificationStateBackfillWorker), and the sharding-key trigger would
        # copy the dangling project_id back, hitting the same FK violation.
        each_sub_batch do |sub_batch|
          connection.execute(delete_orphaned_caches_query(sub_batch: sub_batch))
        end

        super
      end

      private

      # Stacked, MATERIALIZED CTEs bound each step to sub_batch_size so the planner
      # cannot flip the projects lookup into a hash anti-join over a sequential scan
      # of the (very large) projects table; projects is always probed by primary key.
      def delete_orphaned_caches_query(sub_batch:)
        <<~SQL
          WITH sub_batch AS MATERIALIZED (
            #{sub_batch.limit(sub_batch_size).to_sql}
          ),
          filtered_sub_batch AS MATERIALIZED (
            SELECT * FROM sub_batch WHERE #{backfill_column} IS NULL LIMIT #{sub_batch_size}
          ),
          to_delete AS MATERIALIZED (
            SELECT #{backfill_via_table}.#{backfill_via_table_primary_key}
            FROM filtered_sub_batch
            JOIN #{backfill_via_table}
              ON #{backfill_via_table}.#{backfill_via_table_primary_key} = filtered_sub_batch.#{backfill_via_foreign_key}
            LEFT JOIN projects ON projects.id = #{backfill_via_table}.#{backfill_via_column}
            WHERE projects.id IS NULL
            LIMIT #{sub_batch_size}
          )
          DELETE FROM #{backfill_via_table}
          WHERE #{backfill_via_table_primary_key} IN (SELECT #{backfill_via_table_primary_key} FROM to_delete)
        SQL
      end
    end
  end
end
