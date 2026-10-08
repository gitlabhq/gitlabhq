# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Repairs work_item_transitions rows that stopped being synced from issues.
    #
    # The batch one bigint swap left trigger_sync_work_item_transitions_from_issues bound to the
    # retired *_convert_to_bigint columns, because an `UPDATE OF` list is stored by attribute
    # number rather than by name. Updates to moved_to_id, duplicated_to_id and promoted_to_epic_id
    # therefore stopped firing the trigger. The trigger was rebound in 20261005130000, so this
    # only has to repair the rows that drifted in the meantime.
    #
    # Only rows that actually differ are written, so this is a full read of the table but a very
    # small number of updates.
    class BackfillDriftedWorkItemTransitions < BatchedMigrationJob
      operation_name :backfill_drifted_work_item_transitions
      feature_category :team_planning
      cursor :work_item_id

      # The sub-batch carries the current values so the comparison against issues happens while
      # joining it. Rows that already agree are discarded there, which keeps the UPDATE from
      # looking up work_item_transitions again for the rows it is not going to write.
      def perform
        each_sub_batch do |sub_batch|
          result = connection.execute(<<~SQL)
            WITH sub_batch AS MATERIALIZED (
              #{sub_batch.select(:work_item_id, :moved_to_id, :duplicated_to_id, :promoted_to_epic_id)
                         .limit(sub_batch_size).to_sql}
            )
            UPDATE work_item_transitions
            SET moved_to_id = issues.moved_to_id,
                duplicated_to_id = issues.duplicated_to_id,
                promoted_to_epic_id = issues.promoted_to_epic_id
            FROM sub_batch, issues
            WHERE work_item_transitions.work_item_id = sub_batch.work_item_id
              AND issues.id = sub_batch.work_item_id
              AND (
                sub_batch.moved_to_id IS DISTINCT FROM issues.moved_to_id
                OR sub_batch.duplicated_to_id IS DISTINCT FROM issues.duplicated_to_id
                OR sub_batch.promoted_to_epic_id IS DISTINCT FROM issues.promoted_to_epic_id
              )
          SQL

          result.cmd_tuples
        end
      end
    end
  end
end
