# frozen_string_literal: true

class AddVerificationIndexesToCiPipelineArtifacts < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  VERIFICATION_STATE_INDEX_NAME = "index_ci_pipeline_artifacts_verification_state"
  PENDING_VERIFICATION_INDEX_NAME = "index_ci_pipeline_artifacts_pending_verification"
  FAILED_VERIFICATION_INDEX_NAME = "index_ci_pipeline_artifacts_failed_verification"
  NEEDS_VERIFICATION_INDEX_NAME = "index_ci_pipeline_artifacts_needs_verification"

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_pipeline_artifacts, :verification_state, name: VERIFICATION_STATE_INDEX_NAME
    add_concurrent_index :ci_pipeline_artifacts, :verified_at, where: "(verification_state = 0)", order: { verified_at: 'ASC NULLS FIRST' }, name: PENDING_VERIFICATION_INDEX_NAME
    add_concurrent_index :ci_pipeline_artifacts, :verification_retry_at, where: "(verification_state = 3)", order: { verification_retry_at: 'ASC NULLS FIRST' }, name: FAILED_VERIFICATION_INDEX_NAME
    add_concurrent_index :ci_pipeline_artifacts, :verification_state, where: "(verification_state = 0 OR verification_state = 3)", name: NEEDS_VERIFICATION_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ci_pipeline_artifacts, VERIFICATION_STATE_INDEX_NAME
    remove_concurrent_index_by_name :ci_pipeline_artifacts, PENDING_VERIFICATION_INDEX_NAME
    remove_concurrent_index_by_name :ci_pipeline_artifacts, FAILED_VERIFICATION_INDEX_NAME
    remove_concurrent_index_by_name :ci_pipeline_artifacts, NEEDS_VERIFICATION_INDEX_NAME
  end
end
