# frozen_string_literal: true

class AddComponentForeignKeyToSbomOccurrences < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :sbom_occurrences,
      :sbom_components,
      column: :component_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :sbom_occurrences, column: :component_id
    end
  end
end
