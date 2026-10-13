# frozen_string_literal: true

# Disables the reverse sync trigger that mirrors writes from
# merge_request_diff_files into merge_request_diff_files_archived.
#
# DropMergeRequestDiffFilesArchivedReverseSyncTrigger (20260902162109) could
# have timed out, because DROP TRIGGER takes an ACCESS EXCLUSIVE lock on the
# partitioned parent and all of its partitions. If the trigger still exists,
# this migration disables it. ALTER TABLE ... DISABLE TRIGGER takes a SHARE ROW
# EXCLUSIVE lock, which does not block reads, and propagates to every partition.
class DisableMergeRequestDiffFilesArchivedReverseSyncTrigger < Gitlab::Database::Migration[2.4]
  include Gitlab::Database::SchemaHelpers

  milestone '19.5'

  disable_ddl_transaction!

  SOURCE_TABLE         = 'merge_request_diff_files'
  REVERSE_TRIGGER_NAME = 'table_sync_trigger_cd362c20e2_reverse'

  def up
    return unless trigger_exists?(SOURCE_TABLE, REVERSE_TRIGGER_NAME)

    with_lock_retries do
      execute("ALTER TABLE #{SOURCE_TABLE} DISABLE TRIGGER #{REVERSE_TRIGGER_NAME}")
    end
  end

  def down
    return unless trigger_exists?(SOURCE_TABLE, REVERSE_TRIGGER_NAME)

    with_lock_retries do
      execute("ALTER TABLE #{SOURCE_TABLE} ENABLE TRIGGER #{REVERSE_TRIGGER_NAME}")
    end
  end
end
