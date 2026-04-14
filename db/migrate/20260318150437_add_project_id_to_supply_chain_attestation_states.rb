# frozen_string_literal: true

class AddProjectIdToSupplyChainAttestationStates < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def change
    add_column :supply_chain_attestation_states, :project_id, :bigint
  end
end
