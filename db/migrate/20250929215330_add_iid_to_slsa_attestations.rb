# frozen_string_literal: true

class AddIidToSlsaAttestations < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  disable_ddl_transaction!

  INDEX_NAME = 'index_slsa_attestations_on_project_id_iid'

  def up
    add_column :slsa_attestations, :iid, :integer

    add_concurrent_index :slsa_attestations, [:project_id, :iid], name: INDEX_NAME
    remove_concurrent_index_by_name :slsa_attestations, 'index_slsa_attestations_on_project_id'
  end

  def down
    add_concurrent_index :slsa_attestations, :project_id
    remove_concurrent_index_by_name :slsa_attestations, INDEX_NAME

    remove_column :slsa_attestations, :iid
  end
end
