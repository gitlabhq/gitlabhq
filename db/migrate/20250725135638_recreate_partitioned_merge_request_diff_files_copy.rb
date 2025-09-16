# frozen_string_literal: true

class RecreatePartitionedMergeRequestDiffFilesCopy < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '18.3'

  disable_ddl_transaction!

  SOURCE_TABLE_NAME = 'merge_request_diff_files'

  def up
    partitioned_table_name = tmp_table_name(SOURCE_TABLE_NAME)
    function_name = make_sync_function_name(SOURCE_TABLE_NAME)

    # Use a custom table sync trigger function to set sharding key and
    #   deduplicate old_path/new_path
    #
    create_trigger_function(function_name, replace: false) do
      <<~SQL
        IF (TG_OP = 'DELETE') THEN
          DELETE FROM #{partitioned_table_name} where "merge_request_diff_id" = OLD."merge_request_diff_id" AND "relative_order" = OLD."relative_order";
        ELSIF (TG_OP = 'UPDATE') THEN
          UPDATE #{partitioned_table_name}
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
          WHERE #{partitioned_table_name}."merge_request_diff_id" = NEW."merge_request_diff_id" AND #{partitioned_table_name}."relative_order" = NEW."relative_order";
        ELSIF (TG_OP = 'INSERT') THEN
          INSERT INTO #{partitioned_table_name} ("new_file",
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

    partition_table_by_int_range(
      SOURCE_TABLE_NAME,
      'merge_request_diff_id',
      partition_size: 200_000_000,
      primary_key: %w[merge_request_diff_id relative_order]
    )
  end

  def down
    drop_partitioned_table_for(SOURCE_TABLE_NAME)
  end
end
