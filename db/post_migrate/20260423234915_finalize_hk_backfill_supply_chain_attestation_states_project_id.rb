# frozen_string_literal: true

class FinalizeHkBackfillSupplyChainAttestationStatesProjectId < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillSupplyChainAttestationStatesProjectId',
      table_name: :supply_chain_attestation_states,
      column_name: :id,
      job_arguments: [:project_id, :slsa_attestations, :project_id, :supply_chain_attestation_id],
      finalize: true
    )
  end

  def down; end
end
