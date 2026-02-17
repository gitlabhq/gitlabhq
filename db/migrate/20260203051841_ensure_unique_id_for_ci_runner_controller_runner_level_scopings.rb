# frozen_string_literal: true

class EnsureUniqueIdForCiRunnerControllerRunnerLevelScopings < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::UniquenessHelpers

  milestone '18.9'

  TABLE_NAME = :ci_runner_controller_runner_level_scopings
  SEQ_NAME = "ci_runner_controller_runner_level_scopings_id_seq"

  def up
    ensure_unique_id(TABLE_NAME, seq: SEQ_NAME)
  end

  def down
    revert_ensure_unique_id(TABLE_NAME, seq: SEQ_NAME)
  end
end
