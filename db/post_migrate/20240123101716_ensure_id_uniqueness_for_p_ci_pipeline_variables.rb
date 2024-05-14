# frozen_string_literal: true

class EnsureIdUniquenessForPCiPipelineVariables < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::UniquenessHelpers

  milestone '16.9'
  enable_lock_retries!

  TABLE_NAME = :p_ci_pipeline_variables
  SEQ_NAME = :ci_pipeline_variables_id_seq

  def up
    ensure_unique_id(TABLE_NAME, seq: SEQ_NAME)
  end

  def down
    revert_ensure_unique_id(TABLE_NAME, seq: SEQ_NAME)
  end
end
