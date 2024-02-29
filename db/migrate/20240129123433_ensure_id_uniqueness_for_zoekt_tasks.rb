# frozen_string_literal: true

class EnsureIdUniquenessForZoektTasks < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::UniquenessHelpers

  milestone '16.10'

  enable_lock_retries!

  TABLE_NAME = :zoekt_tasks
  SEQ_NAME = :zoekt_tasks_id_seq

  def up
    ensure_unique_id(TABLE_NAME, seq: SEQ_NAME)
  end

  def down
    revert_ensure_unique_id(TABLE_NAME, seq: SEQ_NAME)
  end
end
