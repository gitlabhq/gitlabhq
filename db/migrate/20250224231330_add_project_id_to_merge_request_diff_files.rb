# frozen_string_literal: true

class AddProjectIdToMergeRequestDiffFiles < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::SchemaHelpers
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  disable_ddl_transaction!

  milestone '17.10'

  SOURCE_TABLE = :merge_request_diff_files
  INDEX_NAME = 'index_merge_request_diff_files_on_project_id'

  def up
    with_lock_retries do
      add_column SOURCE_TABLE, :project_id, :bigint, if_not_exists: true
    end

    add_concurrent_foreign_key SOURCE_TABLE, :projects, column: :project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :SOURCE_TABLE, column: :parent_id

      remove_column SOURCE_TABLE, :project_id
    end
  end
end
