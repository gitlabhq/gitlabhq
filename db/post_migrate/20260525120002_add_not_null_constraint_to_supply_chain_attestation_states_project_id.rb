# frozen_string_literal: true

class AddNotNullConstraintToSupplyChainAttestationStatesProjectId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.1'

  def up
    add_not_null_constraint :supply_chain_attestation_states, :project_id
  end

  def down
    remove_not_null_constraint :supply_chain_attestation_states, :project_id
  end
end
