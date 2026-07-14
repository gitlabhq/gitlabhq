# frozen_string_literal: true

class AddFullSyncTargetSequenceToPmCheckpoints < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  def change
    add_column :pm_checkpoints, :full_sync_target_sequence, :integer
  end
end
