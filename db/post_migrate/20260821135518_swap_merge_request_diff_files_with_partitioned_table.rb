# frozen_string_literal: true

class SwapMergeRequestDiffFilesWithPartitionedTable < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '19.4'

  disable_ddl_transaction!

  SOURCE_TABLE      = 'merge_request_diff_files'
  REPLACEMENT_TABLE = 'merge_request_diff_files_99208b8fac'
  ARCHIVED_TABLE    = 'merge_request_diff_files_archived'
  INT4_MAX          = 2_147_483_647

  # The generic replace_table/drop_sync_trigger helpers can't be used here because we need
  # custom reverse sync triggers to keep ARCHIVED_TABLE current while the partitioned table
  # is live, enabling a clean rollback path.
  #
  # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- drop_trigger, ReplaceTable#perform
  # and the trigger creation aren't in the allowed list, but all need the ACCESS EXCLUSIVE lock
  # that with_lock_retries protects.
  def up
    with_lock_retries do
      drop_trigger(SOURCE_TABLE, sync_trigger_name, if_exists: true)
      drop_function(sync_function_name, if_exists: true)

      replace_tables(replacement: REPLACEMENT_TABLE, replaced: ARCHIVED_TABLE)

      create_reverse_sync_trigger
    end
  end

  # Emergency rollback path. The reverse trigger must be dropped before the rename, while
  # SOURCE_TABLE still names the partitioned table it sits on.
  def down
    with_lock_retries do
      drop_trigger(SOURCE_TABLE, reverse_sync_trigger_name, if_exists: true)
      drop_function(reverse_sync_function_name, if_exists: true)

      replace_tables(replacement: ARCHIVED_TABLE, replaced: REPLACEMENT_TABLE)

      create_sync_trigger
    end
  end
  # rubocop:enable Migration/WithLockRetriesDisallowedMethod

  private

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

  def sync_trigger_name
    make_sync_trigger_name(SOURCE_TABLE)
  end

  def sync_function_name
    make_sync_function_name(SOURCE_TABLE)
  end

  def reverse_sync_trigger_name
    "#{sync_trigger_name}_reverse"
  end

  def reverse_sync_function_name
    "#{sync_function_name}_reverse"
  end

  # Creates a row-level trigger that syncs writes from the partitioned table to the archived table.
  # This keeps ARCHIVED_TABLE current for rollback support.
  def create_reverse_sync_trigger
    create_trigger_function(reverse_sync_function_name, replace: true) do
      <<~SQL
        IF (TG_OP = 'DELETE') THEN
          DELETE FROM #{ARCHIVED_TABLE}
          WHERE "merge_request_diff_id" = OLD."merge_request_diff_id"
            AND "relative_order" = OLD."relative_order";
        ELSIF (TG_OP = 'UPDATE') THEN
          IF NEW."merge_request_diff_id" <= #{INT4_MAX} THEN
            UPDATE #{ARCHIVED_TABLE}
            SET "new_file" = NEW."new_file",
              "renamed_file" = NEW."renamed_file",
              "deleted_file" = NEW."deleted_file",
              "too_large" = NEW."too_large",
              "a_mode" = NEW."a_mode",
              "b_mode" = NEW."b_mode",
              "new_path" = NULLIF(NEW."new_path", NEW."old_path"),
              "old_path" = NEW."old_path",
              "diff" = NEW."diff",
              "binary" = NEW."binary",
              "external_diff_offset" = NEW."external_diff_offset",
              "external_diff_size" = NEW."external_diff_size",
              "generated" = NEW."generated",
              "encoded_file_path" = NEW."encoded_file_path",
              "project_id" = NEW."project_id"
            WHERE #{ARCHIVED_TABLE}."merge_request_diff_id" = NEW."merge_request_diff_id"
              AND #{ARCHIVED_TABLE}."relative_order" = NEW."relative_order";
          END IF;
        ELSIF (TG_OP = 'INSERT') THEN
          IF NEW."merge_request_diff_id" <= #{INT4_MAX} THEN
            INSERT INTO #{ARCHIVED_TABLE} (
              "merge_request_diff_id",
              "relative_order",
              "new_file",
              "renamed_file",
              "deleted_file",
              "too_large",
              "a_mode",
              "b_mode",
              "new_path",
              "old_path",
              "diff",
              "binary",
              "external_diff_offset",
              "external_diff_size",
              "generated",
              "encoded_file_path",
              "project_id"
            )
            VALUES (
              NEW."merge_request_diff_id",
              NEW."relative_order",
              NEW."new_file",
              NEW."renamed_file",
              NEW."deleted_file",
              NEW."too_large",
              NEW."a_mode",
              NEW."b_mode",
              NULLIF(NEW."new_path", NEW."old_path"),
              NEW."old_path",
              NEW."diff",
              NEW."binary",
              NEW."external_diff_offset",
              NEW."external_diff_size",
              NEW."generated",
              NEW."encoded_file_path",
              NEW."project_id"
            )
            ON CONFLICT ("merge_request_diff_id", "relative_order") DO NOTHING;
          END IF;
        END IF;

        RETURN NULL;
      SQL
    end

    create_trigger(
      SOURCE_TABLE,
      reverse_sync_trigger_name,
      reverse_sync_function_name,
      fires: 'AFTER INSERT OR UPDATE OR DELETE'
    )
  end

  # Recreates the original sync trigger that syncs from the non-partitioned table to the
  # partitioned table. Used during rollback.
  def create_sync_trigger
    create_trigger_function(sync_function_name, replace: true) do
      <<~SQL
        IF (TG_OP = 'DELETE') THEN
          DELETE FROM #{REPLACEMENT_TABLE} where "merge_request_diff_id" = OLD."merge_request_diff_id" AND "relative_order" = OLD."relative_order";
        ELSIF (TG_OP = 'UPDATE') THEN
          UPDATE #{REPLACEMENT_TABLE}
          SET "new_file" = NEW."new_file",
            "renamed_file" = NEW."renamed_file",
            "deleted_file" = NEW."deleted_file",
            "too_large" = NEW."too_large",
            "a_mode" = NEW."a_mode",
            "b_mode" = NEW."b_mode",
            "new_path" = NULLIF(NEW."new_path", NEW."old_path"),
            "old_path" = NEW."old_path",
            "diff" = NEW."diff",
            "binary" = NEW."binary",
            "external_diff_offset" = NEW."external_diff_offset",
            "external_diff_size" = NEW."external_diff_size",
            "generated" = NEW."generated",
            "encoded_file_path" = NEW."encoded_file_path",
            "project_id" = COALESCE(NEW."project_id", (SELECT mrd.project_id FROM merge_request_diffs mrd WHERE mrd.id = NEW."merge_request_diff_id"))
          WHERE #{REPLACEMENT_TABLE}."merge_request_diff_id" = NEW."merge_request_diff_id" AND #{REPLACEMENT_TABLE}."relative_order" = NEW."relative_order";
        ELSIF (TG_OP = 'INSERT') THEN
          INSERT INTO #{REPLACEMENT_TABLE} ("new_file",
            "renamed_file",
            "deleted_file",
            "too_large",
            "a_mode",
            "b_mode",
            "new_path",
            "old_path",
            "diff",
            "binary",
            "external_diff_offset",
            "external_diff_size",
            "generated",
            "encoded_file_path",
            "project_id",
            "merge_request_diff_id",
            "relative_order")
          VALUES (NEW."new_file",
            NEW."renamed_file",
            NEW."deleted_file",
            NEW."too_large",
            NEW."a_mode",
            NEW."b_mode",
            NULLIF(NEW."new_path", NEW."old_path"),
            NEW."old_path",
            NEW."diff",
            NEW."binary",
            NEW."external_diff_offset",
            NEW."external_diff_size",
            NEW."generated",
            NEW."encoded_file_path",
            COALESCE(NEW."project_id", (SELECT mrd.project_id FROM merge_request_diffs mrd WHERE mrd.id = NEW."merge_request_diff_id")),
            NEW."merge_request_diff_id",
            NEW."relative_order");
        END IF;
        RETURN NULL;
      SQL
    end

    execute <<~SQL
      COMMENT ON FUNCTION #{sync_function_name}()
      IS 'Partitioning migration: table sync for #{SOURCE_TABLE} table'
    SQL

    create_trigger(
      SOURCE_TABLE,
      sync_trigger_name,
      sync_function_name,
      fires: 'AFTER INSERT OR UPDATE OR DELETE'
    )
  end
end
