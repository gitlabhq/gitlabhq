# frozen_string_literal: true

# Adds a BEFORE UPDATE trigger on the `notes` table that nulls out
# `namespace_id` whenever a row has both `namespace_id` and `project_id`
# set (a "dual-key" row).  This lets us add the strict
# `num_nonnulls(...) = 1` check constraint as NOT VALID while the
# CleanupDualShardingKeysInNotes BBM is still running, because any
# UPDATE that touches a dirty row will silently repair it in-place.
#
# A trigger-level WHEN clause restricts firing to dual-key rows, so
# Postgres skips the function call entirely for already-compliant rows
# and overhead on this very hot table is minimal.
#
# Organization-keyed rows (personal snippets, abuse-report notes) have
# project_id NULL, so the guard already excludes them - no special
# handling is needed.
class AddRepairDualShardingKeyTriggerToNotes < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::SchemaHelpers

  milestone '19.4'

  disable_ddl_transaction!

  FUNCTION_NAME = 'repair_dual_sharding_key_on_notes'
  TRIGGER_NAME = 'trigger_817aa51bc4f2'
  TABLE_NAME = :notes

  def up
    # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- lock retries
    # are recommended for trigger creation on high-traffic tables (notes is in
    # OverLimitTables).  CREATE OR REPLACE FUNCTION takes no lock on notes, so
    # creating it inside the block does not extend the lock window, and a failed
    # retry does not leave an orphaned function behind.
    with_lock_retries do
      create_trigger_function(FUNCTION_NAME, replace: true) do
        <<~SQL
          NEW.namespace_id := NULL;

          RETURN NEW;
        SQL
      end

      drop_trigger(TABLE_NAME, TRIGGER_NAME)
      create_trigger(TABLE_NAME, TRIGGER_NAME, FUNCTION_NAME, fires: 'BEFORE UPDATE') do
        'WHEN (NEW.namespace_id IS NOT NULL AND NEW.project_id IS NOT NULL)'
      end
    end
    # rubocop:enable Migration/WithLockRetriesDisallowedMethod
  end

  def down
    # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- same rationale as above
    with_lock_retries do
      drop_trigger(TABLE_NAME, TRIGGER_NAME)
    end
    # rubocop:enable Migration/WithLockRetriesDisallowedMethod

    drop_function(FUNCTION_NAME)
  end
end
