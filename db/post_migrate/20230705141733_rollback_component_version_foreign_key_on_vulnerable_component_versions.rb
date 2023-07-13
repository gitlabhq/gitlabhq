# frozen_string_literal: true

class RollbackComponentVersionForeignKeyOnVulnerableComponentVersions < Gitlab::Database::Migration[2.1]
  SOURCE_TABLE = :sbom_vulnerable_component_versions
  TARGET_TABLE = :sbom_component_versions
  COLUMN = :sbom_component_version_id

  disable_ddl_transaction!

  def up
    # Foreign key is removed when the table is dropped in the next migration.
  end

  def down
    add_concurrent_foreign_key SOURCE_TABLE, TARGET_TABLE, column: COLUMN, on_delete: :cascade
  end
end
