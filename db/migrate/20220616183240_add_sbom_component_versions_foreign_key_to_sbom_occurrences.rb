# frozen_string_literal: true

class AddSbomComponentVersionsForeignKeyToSbomOccurrences < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :sbom_occurrences,
      :sbom_component_versions,
      column: :component_version_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :sbom_occurrences, column: :component_version_id
    end
  end
end
