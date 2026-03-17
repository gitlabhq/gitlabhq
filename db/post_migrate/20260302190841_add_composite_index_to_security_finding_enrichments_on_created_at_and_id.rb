# frozen_string_literal: true

class AddCompositeIndexToSecurityFindingEnrichmentsOnCreatedAtAndId < Gitlab::Database::Migration[2.3]
  milestone '18.10'
  disable_ddl_transaction!

  OLD_INDEX_NAME = 'index_sec_finding_enrichments_on_created_at'
  NEW_INDEX_NAME = 'index_sec_finding_enrichments_on_created_at_and_id'

  def up
    add_concurrent_index :security_finding_enrichments, [:created_at, :id], name: NEW_INDEX_NAME
    remove_concurrent_index_by_name :security_finding_enrichments, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :security_finding_enrichments, [:created_at], name: OLD_INDEX_NAME
    remove_concurrent_index_by_name :security_finding_enrichments, NEW_INDEX_NAME
  end
end
