# frozen_string_literal: true

class AddTriggersToPartitionedMergeRequestDiffCommits < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '18.11'

  disable_ddl_transaction!

  SOURCE_TABLE_NAME = 'merge_request_diff_commits'

  # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- We are creating
  # sync triggers here which is technically the same as create_trigger_to_sync_tables
  # which is allowed.
  def up
    with_lock_retries do
      create_sync_triggers
    end
  end

  def down
    with_lock_retries do
      drop_trigger(SOURCE_TABLE_NAME, trigger_name_insert, if_exists: true)
      drop_trigger(SOURCE_TABLE_NAME, trigger_name_delete, if_exists: true)
    end

    drop_function(insert_function_name, if_exists: true)
    drop_function(delete_function_name, if_exists: true)
  end
  # rubocop:enable Migration/WithLockRetriesDisallowedMethod

  private

  def create_sync_triggers
    # Create function for INSERT
    create_trigger_function(insert_function_name, replace: true) do
      <<~SQL
        INSERT INTO #{partitioned_table_name}
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

    # Create function for DELETE
    create_trigger_function(delete_function_name, replace: true) do
      <<~SQL
        DELETE FROM #{partitioned_table_name}
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

    # Create INSERT trigger
    execute(<<~SQL.squish)
      CREATE OR REPLACE TRIGGER #{trigger_name_insert}
      AFTER INSERT ON #{SOURCE_TABLE_NAME}
      REFERENCING NEW TABLE AS new_table
      FOR EACH STATEMENT
      EXECUTE FUNCTION #{insert_function_name}();
    SQL

    # Create DELETE trigger
    execute(<<~SQL.squish)
      CREATE OR REPLACE TRIGGER #{trigger_name_delete}
      AFTER DELETE ON #{SOURCE_TABLE_NAME}
      REFERENCING OLD TABLE AS old_table
      FOR EACH STATEMENT
      EXECUTE FUNCTION #{delete_function_name}();
    SQL
  end

  def partitioned_table_name
    @_partitioned_table_name ||= tmp_table_name(SOURCE_TABLE_NAME)
  end

  def insert_function_name
    @_insert_function_name ||= "#{make_sync_function_name(SOURCE_TABLE_NAME)}_insert"
  end

  def delete_function_name
    @_delete_function_name ||= "#{make_sync_function_name(SOURCE_TABLE_NAME)}_delete"
  end

  def trigger_name_insert
    @_trigger_name_insert ||= "#{make_sync_trigger_name(SOURCE_TABLE_NAME)}_insert"
  end

  def trigger_name_delete
    @_trigger_name_delete ||= "#{make_sync_trigger_name(SOURCE_TABLE_NAME)}_delete"
  end
end
