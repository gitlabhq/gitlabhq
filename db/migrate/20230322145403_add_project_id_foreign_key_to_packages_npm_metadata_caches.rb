# frozen_string_literal: true

class AddProjectIdForeignKeyToPackagesNpmMetadataCaches < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  SOURCE_TABLE = :packages_npm_metadata_caches
  TARGET_TABLE = :projects
  COLUMN = :project_id

  def up
    add_concurrent_foreign_key SOURCE_TABLE, TARGET_TABLE, column: COLUMN, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key SOURCE_TABLE, column: COLUMN
    end
  end
end
