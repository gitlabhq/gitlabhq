# frozen_string_literal: true

class DropIncorrectSbomOccurrencesIndexUsingComponentVersionId < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  disable_ddl_transaction!

  INDEX_NAME = 'idx_sbom_occurr_on_traversal_ids_and_comp_name_and_comp_ver_id'

  def up
    remove_concurrent_index_by_name :sbom_occurrences, INDEX_NAME
  end

  def down
    add_concurrent_index :sbom_occurrences,
      'traversal_ids, component_name COLLATE "C", component_version_id',
      name: INDEX_NAME
  end
end
