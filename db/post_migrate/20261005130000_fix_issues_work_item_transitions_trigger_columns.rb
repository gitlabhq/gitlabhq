# frozen_string_literal: true

# `trigger_sync_work_item_transitions_from_issues` fires on `UPDATE OF` specific columns.
# PostgreSQL stores that list as attribute numbers rather than names, so the column renames
# performed by the batch one bigint swap (20260916090001) left the trigger bound to the old
# integer columns, which are now named `*_convert_to_bigint`. Updates to the live columns
# therefore stopped syncing to `work_item_transitions`.
#
# 20260916090001 now recreates the trigger as part of the swap, which covers instances that
# have not run it yet. This migration repairs instances where the swap already ran.
#
# Recreating the trigger by name is idempotent: on an instance that never had the conversion
# columns, the resulting definition is identical to the existing one.
class FixIssuesWorkItemTransitionsTriggerColumns < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::SchemaHelpers

  milestone '19.5'

  disable_ddl_transaction!

  TABLE_NAME = 'issues'
  TRIGGER_NAME = 'trigger_sync_work_item_transitions_from_issues'
  FUNCTION_NAME = 'sync_work_item_transitions_from_issues'
  FIRES = 'AFTER INSERT OR UPDATE OF moved_to_id, duplicated_to_id, promoted_to_epic_id, namespace_id'

  def up
    return unless trigger_exists?(TABLE_NAME, TRIGGER_NAME)

    # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- recommended for
    # trigger creation on issues, a high-traffic table
    with_lock_retries do
      create_trigger(TABLE_NAME, TRIGGER_NAME, FUNCTION_NAME, fires: FIRES, replace: true)
    end
    # rubocop:enable Migration/WithLockRetriesDisallowedMethod
  end

  def down
    # No-op. The previous column binding was the defect being corrected, so there is nothing
    # meaningful to restore.
  end
end
