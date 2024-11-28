# frozen_string_literal: true

class AddArchivedAndTraversalIdsColumnsToSbomOccurrences < Gitlab::Database::Migration[2.2]
  milestone '16.9'

  def change
    # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
    add_column :sbom_occurrences, :archived, :boolean, default: false, null: false
    # rubocop:enable Migration/PreventAddingColumns
    # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
    add_column :sbom_occurrences, :traversal_ids, 'bigint[]', default: [], null: false
    # rubocop:enable Migration/PreventAddingColumns
  end
end
