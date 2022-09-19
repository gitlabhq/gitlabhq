# frozen_string_literal: true

class AddSbomComponentVersionForeignKeyToSbomVulnerableComponentVersions < Gitlab::Database::Migration[2.0]
  SOURCE_TABLE = :sbom_vulnerable_component_versions
  TARGET_TABLE = :sbom_component_versions
  COLUMN = :sbom_component_version_id

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key SOURCE_TABLE, TARGET_TABLE, column: COLUMN, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key SOURCE_TABLE, column: COLUMN
    end
  end
end
