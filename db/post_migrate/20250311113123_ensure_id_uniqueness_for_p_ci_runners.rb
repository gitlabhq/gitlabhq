# frozen_string_literal: true

class EnsureIdUniquenessForPCiRunners < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::UniquenessHelpers

  milestone '17.10'

  TABLE_NAME = :ci_runners
  SEQ_NAME = :ci_runners_id_seq

  def up
    ensure_unique_id(TABLE_NAME, seq: SEQ_NAME)
  end

  def down
    revert_ensure_unique_id(TABLE_NAME, seq: SEQ_NAME)
  end
end
