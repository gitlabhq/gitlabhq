# frozen_string_literal: true

class DropMergeRequestDiffFilesArchivedReverseSyncTrigger < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::SchemaHelpers

  milestone '19.5'

  disable_ddl_transaction!

  SOURCE_TABLE            = 'merge_request_diff_files'
  ARCHIVED_TABLE          = 'merge_request_diff_files_archived'
  REVERSE_TRIGGER_NAME    = 'table_sync_trigger_cd362c20e2_reverse'
  REVERSE_FUNCTION_NAME   = 'table_sync_function_3f39f64fc3_reverse'
  INT4_MAX                = 2_147_483_647

  # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- trigger/function DDL needs the ACCESS EXCLUSIVE lock with_lock_retries provides
  def up
    with_lock_retries do
      drop_trigger(SOURCE_TABLE, REVERSE_TRIGGER_NAME, if_exists: true)
      drop_function(REVERSE_FUNCTION_NAME)
    end
  end

  def down
    with_lock_retries do
      create_reverse_sync_trigger
    end
  end
  # rubocop:enable Migration/WithLockRetriesDisallowedMethod

  private

  def create_reverse_sync_trigger
    create_trigger_function(REVERSE_FUNCTION_NAME, replace: true) do
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
      REVERSE_TRIGGER_NAME,
      REVERSE_FUNCTION_NAME,
      fires: 'AFTER INSERT OR UPDATE OR DELETE'
    )
  end
end
