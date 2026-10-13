# frozen_string_literal: true

class DropMergeRequestDiffCommitsReverseSyncTriggers < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '19.5'

  disable_ddl_transaction!

  SOURCE_TABLE   = 'merge_request_diff_commits'
  ARCHIVED_TABLE = 'merge_request_diff_commits_archived'
  INT4_MAX = 2_147_483_647

  # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- drop_trigger and the trigger creation
  # aren't in the allowed list, but both need the ACCESS EXCLUSIVE lock that with_lock_retries protects.
  def up
    return unless Gitlab.com_except_jh? && connection.table_exists?(ARCHIVED_TABLE)

    with_lock_retries do
      drop_trigger(SOURCE_TABLE, sync_trigger_name('reverse_insert'), if_exists: true)
      drop_trigger(SOURCE_TABLE, sync_trigger_name('reverse_delete'), if_exists: true)
      drop_function(sync_function_name('reverse_insert'), if_exists: true)
      drop_function(sync_function_name('reverse_delete'), if_exists: true)
    end
  end

  def down
    return unless Gitlab.com_except_jh? && connection.table_exists?(ARCHIVED_TABLE)

    with_lock_retries do
      create_reverse_sync_triggers
    end
  end
  # rubocop:enable Migration/WithLockRetriesDisallowedMethod

  private

  def sync_trigger_name(suffix)
    "#{make_sync_trigger_name(SOURCE_TABLE)}_#{suffix}"
  end

  def sync_function_name(suffix)
    "#{make_sync_function_name(SOURCE_TABLE)}_#{suffix}"
  end

  # Mirrors SwapMergeRequestDiffCommitsTable#create_reverse_sync_triggers. Duplicated rather than
  # reused so this migration stays a self-contained snapshot of the schema change.
  def create_reverse_sync_triggers
    create_trigger_function(sync_function_name('reverse_insert'), replace: true) do
      <<~SQL
        INSERT INTO #{ARCHIVED_TABLE}
          (merge_request_commits_metadata_id, project_id, merge_request_diff_id, relative_order)
        SELECT
          new_table.merge_request_commits_metadata_id,
          new_table.project_id,
          new_table.merge_request_diff_id,
          new_table.relative_order
        FROM new_table
        WHERE new_table.merge_request_diff_id <= #{INT4_MAX}
        ON CONFLICT (merge_request_diff_id, relative_order) DO NOTHING;

        RETURN NULL;
      SQL
    end

    create_trigger_function(sync_function_name('reverse_delete'), replace: true) do
      <<~SQL
        DELETE FROM #{ARCHIVED_TABLE}
        WHERE (merge_request_diff_id, relative_order) IN (
          SELECT
            old_table.merge_request_diff_id,
            old_table.relative_order
          FROM old_table
        );

        RETURN NULL;
      SQL
    end

    create_statement_trigger(suffix: 'reverse_insert', event: 'INSERT', transition: 'NEW TABLE AS new_table')
    create_statement_trigger(suffix: 'reverse_delete', event: 'DELETE', transition: 'OLD TABLE AS old_table')
  end

  def create_statement_trigger(suffix:, event:, transition:)
    execute(<<~SQL.squish)
      CREATE OR REPLACE TRIGGER #{sync_trigger_name(suffix)}
      AFTER #{event} ON #{SOURCE_TABLE}
      REFERENCING #{transition}
      FOR EACH STATEMENT
      EXECUTE FUNCTION #{sync_function_name(suffix)}();
    SQL
  end
end
