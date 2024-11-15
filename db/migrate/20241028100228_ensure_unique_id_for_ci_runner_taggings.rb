# frozen_string_literal: true

class EnsureUniqueIdForCiRunnerTaggings < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::UniquenessHelpers

  milestone '17.6'

  TABLE_NAME = :ci_runner_taggings
  SEQ_NAME = :ci_runner_taggings_id_seq

  def up
    ensure_unique_id(TABLE_NAME, seq: SEQ_NAME)
  end

  def down
    revert_ensure_unique_id(TABLE_NAME, seq: SEQ_NAME)
  end
end
