# frozen_string_literal: true

class IndexSbomOccurrencesOnUuid < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_sbom_occurrences_on_uuid'

  disable_ddl_transaction!

  def up
    add_concurrent_index :sbom_occurrences, :uuid, unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :sbom_occurrences, name: INDEX_NAME
  end
end
