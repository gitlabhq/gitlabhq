# frozen_string_literal: true

class IndexSupplyChainAttestationStatesOnProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.11'
  disable_ddl_transaction!

  INDEX_NAME = 'index_supply_chain_attestation_states_on_project_id'

  def up
    add_concurrent_index :supply_chain_attestation_states, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :supply_chain_attestation_states, INDEX_NAME
  end
end
