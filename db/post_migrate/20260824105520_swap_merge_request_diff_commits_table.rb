# frozen_string_literal: true

class SwapMergeRequestDiffCommitsTable < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '19.4'

  disable_ddl_transaction!

  SOURCE_TABLE      = 'merge_request_diff_commits'
  REPLACEMENT_TABLE = 'merge_request_diff_commits_b5377a7a34'
  ARCHIVED_TABLE    = 'merge_request_diff_commits_archived'

  # The generic replace_table/drop_sync_trigger helpers can't be used here: this table's sync
  # triggers are a custom suffixed _insert/_delete pair (statement-level, transition tables) the
  # generic helpers don't know about, the two tables don't share the same column set, and the
  # rename needs lock-acquisition retries. The reverse sync triggers keep ARCHIVED_TABLE current
  # while the partitioned table is live, so a rollback reinstates a complete table.
  #
  # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- drop_trigger, ReplaceTable#perform
  # and the trigger creation aren't in the allowed list, but all need the ACCESS EXCLUSIVE lock
  # that with_lock_retries protects.
  def up
    return unless Gitlab.com_except_jh?

    with_lock_retries do
      drop_trigger(SOURCE_TABLE, sync_trigger_name('insert'), if_exists: true)
      drop_trigger(SOURCE_TABLE, sync_trigger_name('delete'), if_exists: true)
      drop_function(sync_function_name('insert'), if_exists: true)
      drop_function(sync_function_name('delete'), if_exists: true)

      replace_tables(replacement: REPLACEMENT_TABLE, replaced: ARCHIVED_TABLE) unless tables_swapped?

      create_reverse_sync_triggers
    end
  end

  # Emergency path only. The reverse triggers must be dropped before the rename, while
  # SOURCE_TABLE still names the partitioned table they sit on.
  def down
    return unless Gitlab.com_except_jh?

    with_lock_retries do
      drop_trigger(SOURCE_TABLE, sync_trigger_name('reverse_insert'), if_exists: true)
      drop_trigger(SOURCE_TABLE, sync_trigger_name('reverse_delete'), if_exists: true)
      drop_function(sync_function_name('reverse_insert'), if_exists: true)
      drop_function(sync_function_name('reverse_delete'), if_exists: true)

      replace_tables(replacement: ARCHIVED_TABLE, replaced: REPLACEMENT_TABLE) if tables_swapped?

      create_sync_triggers
    end
  end
  # rubocop:enable Migration/WithLockRetriesDisallowedMethod

  private

  # The rename is the only step that isn't idempotent, so it is the only one guarded: a re-run
  # after a partial or unrecorded run still (re)creates the triggers for the current layout.
  def tables_swapped?
    connection.table_exists?(ARCHIVED_TABLE)
  end

  def replace_tables(replacement:, replaced:)
    Gitlab::Database::Partitioning::ReplaceTable.new(
      connection,
      SOURCE_TABLE,
      replacement,
      replaced,
      'merge_request_diff_id',
      rename_partitions: true
    ).perform
  end

  def sync_trigger_name(suffix)
    "#{make_sync_trigger_name(SOURCE_TABLE)}_#{suffix}"
  end

  def sync_function_name(suffix)
    "#{make_sync_function_name(SOURCE_TABLE)}_#{suffix}"
  end

  # Mirrors AddTriggersToPartitionedMergeRequestDiffCommits. CREATE OR REPLACE on both the
  # functions and triggers keeps a failed-and-retried run idempotent.
  def create_sync_triggers
    create_trigger_function(sync_function_name('insert'), replace: true) do
      <<~SQL
        INSERT INTO #{REPLACEMENT_TABLE}
          (merge_request_commits_metadata_id, project_id, merge_request_diff_id, relative_order)
        SELECT
          new_table.merge_request_commits_metadata_id,
          new_table.project_id,
          new_table.merge_request_diff_id,
          new_table.relative_order
        FROM new_table
        WHERE new_table.merge_request_commits_metadata_id IS NOT NULL
          AND new_table.project_id IS NOT NULL;

        RETURN NULL;
      SQL
    end

    create_trigger_function(sync_function_name('delete'), replace: true) do
      <<~SQL
        DELETE FROM #{REPLACEMENT_TABLE}
        WHERE (merge_request_diff_id, relative_order, project_id) IN (
          SELECT
            old_table.merge_request_diff_id,
            old_table.relative_order,
            old_table.project_id
          FROM old_table
          WHERE old_table.project_id IS NOT NULL
        );

        RETURN NULL;
      SQL
    end

    create_statement_trigger(suffix: 'insert', event: 'INSERT', transition: 'NEW TABLE AS new_table')
    create_statement_trigger(suffix: 'delete', event: 'DELETE', transition: 'OLD TABLE AS old_table')
  end

  # Syncs only the four columns both tables share, matching what the application writes.
  # ON CONFLICT DO NOTHING keeps pre-existing archived rows instead of aborting the write.
  # The archived table's merge_request_diff_id can be physically int4 on long-lived
  # instances, so the reverse sync must skip rows past the int4 ceiling.
  def create_reverse_sync_triggers
    create_trigger_function(sync_function_name('reverse_insert')) do
      <<~SQL
        INSERT INTO #{ARCHIVED_TABLE}
          (merge_request_commits_metadata_id, project_id, merge_request_diff_id, relative_order)
        SELECT
          new_table.merge_request_commits_metadata_id,
          new_table.project_id,
          new_table.merge_request_diff_id,
          new_table.relative_order
        FROM new_table
        WHERE new_table.merge_request_diff_id <= 2147483647
        ON CONFLICT (merge_request_diff_id, relative_order) DO NOTHING;

        RETURN NULL;
      SQL
    end

    create_trigger_function(sync_function_name('reverse_delete')) do
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
