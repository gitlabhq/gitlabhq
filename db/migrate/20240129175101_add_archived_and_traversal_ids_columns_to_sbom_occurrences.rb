# frozen_string_literal: true

class AddArchivedAndTraversalIdsColumnsToSbomOccurrences < Gitlab::Database::Migration[2.2]
  milestone '16.9'

  def change
    add_column :sbom_occurrences, :archived, :boolean, default: false, null: false
    add_column :sbom_occurrences, :traversal_ids, 'bigint[]', default: [], null: false
  end
end
