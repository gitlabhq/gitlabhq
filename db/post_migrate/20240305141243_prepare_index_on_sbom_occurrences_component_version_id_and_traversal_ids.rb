# frozen_string_literal: true

class PrepareIndexOnSbomOccurrencesComponentVersionIdAndTraversalIds < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'idx_sbom_occurrences_on_component_version_id_and_traversal_ids'

  milestone '16.11'

  # rubocop:disable Migration/PreventIndexCreation -- Legacy migration
  def up
    prepare_async_index :sbom_occurrences, [:component_version_id, :traversal_ids], name: INDEX_NAME
  end
  # rubocop:enable Migration/PreventIndexCreation

  def down
    unprepare_async_index :sbom_occurrences, INDEX_NAME
  end
end
