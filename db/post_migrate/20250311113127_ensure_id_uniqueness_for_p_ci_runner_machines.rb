# frozen_string_literal: true

class EnsureIdUniquenessForPCiRunnerMachines < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::UniquenessHelpers

  milestone '17.10'
  enable_lock_retries!

  TABLE_NAME = :ci_runner_machines
  SEQ_NAME = :ci_runner_machines_id_seq

  def up
    ensure_unique_id(TABLE_NAME, seq: SEQ_NAME)
  end

  def down
    revert_ensure_unique_id(TABLE_NAME, seq: SEQ_NAME)
  end
end
