# frozen_string_literal: true

class AddUniqueIndexToSlsaAttestationsProjectIdIid < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  disable_ddl_transaction!

  INDEX_NAME = 'index_slsa_attestations_on_project_id_iid'

  def up
    remove_concurrent_index_by_name :slsa_attestations, INDEX_NAME, if_exists: true
    add_concurrent_index :slsa_attestations, [:project_id, :iid], name: INDEX_NAME, unique: true
  end

  def down
    remove_concurrent_index_by_name :slsa_attestations, INDEX_NAME, if_exists: true
    add_concurrent_index :slsa_attestations, [:project_id, :iid], name: INDEX_NAME
  end
end
