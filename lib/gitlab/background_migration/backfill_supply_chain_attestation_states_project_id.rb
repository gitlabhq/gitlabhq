# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillSupplyChainAttestationStatesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_supply_chain_attestation_states_project_id
      feature_category :geo_replication
    end
  end
end
