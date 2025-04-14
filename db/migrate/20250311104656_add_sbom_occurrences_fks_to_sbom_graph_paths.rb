# frozen_string_literal: true

class AddSbomOccurrencesFksToSbomGraphPaths < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.11'

  def up
    add_concurrent_foreign_key :sbom_graph_paths, :sbom_occurrences, column: :ancestor_id,
      on_delete: :cascade
    add_concurrent_foreign_key :sbom_graph_paths, :sbom_occurrences, column: :descendant_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :sbom_graph_paths, column: :ancestor_id
      remove_foreign_key :sbom_graph_paths, column: :descendant_id
    end
  end
end
