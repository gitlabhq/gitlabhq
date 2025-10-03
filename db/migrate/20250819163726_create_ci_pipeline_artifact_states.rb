# frozen_string_literal: true

class CreateCiPipelineArtifactStates < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  TABLE_NAME = :p_ci_pipeline_artifact_states
  def up
    create_table TABLE_NAME, primary_key: [:pipeline_artifact_id, :partition_id],
      options: 'PARTITION BY LIST (partition_id)', if_not_exists: true do |t| # -- False positive
      t.datetime_with_timezone :verification_started_at
      t.datetime_with_timezone :verification_retry_at
      t.datetime_with_timezone :verified_at
      t.bigint :pipeline_artifact_id, null: false
      t.bigint :partition_id, null: false

      t.integer :verification_state, default: 0, limit: 2, null: false
      t.integer :verification_retry_count, default: 0, limit: 2

      t.binary :verification_checksum, using: 'verification_checksum::bytea'
      t.text :verification_failure, limit: 255

      t.index [:pipeline_artifact_id, :partition_id], unique: true,
        name: 'index_ci_pipeline_artifact_states_on_artifact_and_partition'
      t.index [:verification_state, :pipeline_artifact_id],
        name: 'index_on_pipeline_artifact_id_partition_id_verification_state'

      t.index [:pipeline_artifact_id, :verification_started_at],
        where: "(verification_state = 1)",
        name: 'index_ci_pipeline_artifact_states_on_verification_started'

      t.index :pipeline_artifact_id,
        where: "(verification_state = 0 OR verification_state = 3)",
        name: 'index_ci_pipeline_artifact_states_needs_verification_id'

      t.index :verified_at,
        where: "(verification_state = 0)",
        order: { verified_at: 'ASC NULLS FIRST' },
        name: 'index_ci_pipeline_artifact_states_pending_verification'
      t.index :verification_retry_at,
        where: "(verification_state = 3)",
        order: { verification_retry_at: 'ASC NULLS FIRST' },
        name: 'index_ci_pipeline_artifact_states_failed_verification'
    end
  end

  def down
    drop_table TABLE_NAME, if_exists: true
  end
end
