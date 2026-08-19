# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Deletes web_hook_logs_daily rows that violate the sharding-key constraint
    # check_19dc80d658 (num_nonnulls(organization_id, group_id, project_id) != 1) and whose
    # parent web_hook no longer exists. These are orphaned log rows the finalize backfill could
    # not assign a sharding key to, and they must be removed before the constraint can be
    # validated. Runs only on self-managed instances (the queueing migration skips .com, which
    # has no such rows), so it is not bound by a deploy migration window on a large table.
    # See https://gitlab.com/gitlab-org/gitlab/-/work_items/603303
    class CleanupWebHookLogsDailyShardingKeyOrphans < BatchedMigrationJob
      cursor :id, :created_at
      operation_name :delete_sharding_key_orphans
      feature_category :webhooks

      def perform
        each_sub_batch do |sub_batch|
          # Resolve the sub-batch ids into a materialized CTE first so the planner cannot lead
          # with the unindexed web_hooks anti-join: the num_nonnulls check and the anti-join are
          # only ever evaluated against that bounded set, and AND short-circuits on num_nonnulls
          # before probing web_hooks for the rare violating rows.
          connection.execute(<<~SQL)
            WITH batch AS MATERIALIZED (
              #{sub_batch.select(:id).limit(sub_batch_size).to_sql}
            )
            DELETE FROM web_hook_logs_daily
            WHERE id IN (SELECT id FROM batch)
              AND num_nonnulls(organization_id, group_id, project_id) != 1
              AND NOT EXISTS (
                SELECT 1 FROM web_hooks WHERE web_hooks.id = web_hook_logs_daily.web_hook_id
              )
          SQL
        end
      end
    end
  end
end
