# frozen_string_literal: true

class AddSupplyChainAttestationStatesProjectIdTrigger < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def up
    install_sharding_key_assignment_trigger(
      table: :supply_chain_attestation_states,
      sharding_key: :project_id,
      parent_table: :slsa_attestations,
      parent_sharding_key: :project_id,
      foreign_key: :supply_chain_attestation_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :supply_chain_attestation_states,
      sharding_key: :project_id,
      parent_table: :slsa_attestations,
      parent_sharding_key: :project_id,
      foreign_key: :supply_chain_attestation_id
    )
  end
end
