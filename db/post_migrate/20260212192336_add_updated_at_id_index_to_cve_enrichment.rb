# frozen_string_literal: true

class AddUpdatedAtIdIndexToCveEnrichment < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'index_pm_cve_enrichment_on_updated_at_and_id'

  milestone '18.9'
  disable_ddl_transaction!

  def up
    add_concurrent_index :pm_cve_enrichment, [:updated_at, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :pm_cve_enrichment, INDEX_NAME
  end
end
