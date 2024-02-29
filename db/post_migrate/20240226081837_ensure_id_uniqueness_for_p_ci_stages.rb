# frozen_string_literal: true

class EnsureIdUniquenessForPCiStages < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::UniquenessHelpers

  milestone '16.10'
  enable_lock_retries!

  TABLE_NAME = :p_ci_stages
  SEQ_NAME = :ci_stages_id_seq

  def up
    ensure_unique_id(TABLE_NAME, seq: SEQ_NAME)
  end

  def down
    revert_ensure_unique_id(TABLE_NAME, seq: SEQ_NAME)
  end
end
