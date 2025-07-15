# frozen_string_literal: true

class EnsureIdUniquenessForPDuoWorkflowsCheckpoints < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::UniquenessHelpers

  milestone '18.2'

  TABLE_NAME = :p_duo_workflows_checkpoints
  SEQ_NAME = :p_duo_workflows_checkpoints_id_seq

  def up
    ensure_unique_id(TABLE_NAME, seq: SEQ_NAME)
  end

  def down
    revert_ensure_unique_id(TABLE_NAME, seq: SEQ_NAME)
  end
end
