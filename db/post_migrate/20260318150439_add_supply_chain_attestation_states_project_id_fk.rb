# frozen_string_literal: true

class AddSupplyChainAttestationStatesProjectIdFk < Gitlab::Database::Migration[2.3]
  milestone '18.11'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :supply_chain_attestation_states, :projects, column: :project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :supply_chain_attestation_states, column: :project_id
    end
  end
end
