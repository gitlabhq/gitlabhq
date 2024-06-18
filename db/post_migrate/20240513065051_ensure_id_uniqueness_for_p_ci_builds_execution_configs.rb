# frozen_string_literal: true

class EnsureIdUniquenessForPCiBuildsExecutionConfigs < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::UniquenessHelpers

  milestone '17.1'
  enable_lock_retries!

  TABLE_NAME = :p_ci_builds_execution_configs
  SEQ_NAME = :p_ci_builds_execution_configs_id_seq

  def up
    ensure_unique_id(TABLE_NAME, seq: SEQ_NAME)
  end

  def down
    revert_ensure_unique_id(TABLE_NAME, seq: SEQ_NAME)
  end
end
