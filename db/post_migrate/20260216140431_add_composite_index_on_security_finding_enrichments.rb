# frozen_string_literal: true

class AddCompositeIndexOnSecurityFindingEnrichments < Gitlab::Database::Migration[2.3]
  OLD_INDEX_NAME = 'index_sec_finding_enrichments_on_cve_enrichment_id'
  NEW_INDEX_NAME = 'index_security_finding_enrichments_on_cve_enrichment_id_and_id'

  milestone '18.10'
  disable_ddl_transaction!

  def up
    add_concurrent_index :security_finding_enrichments, [:cve_enrichment_id, :id], name: NEW_INDEX_NAME
    remove_concurrent_index_by_name :security_finding_enrichments, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :security_finding_enrichments, [:cve_enrichment_id], name: OLD_INDEX_NAME
    remove_concurrent_index_by_name :security_finding_enrichments, NEW_INDEX_NAME
  end
end
