# frozen_string_literal: true

class RemoveStageEventHashesUniqueIndex < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.2'

  INDEX = 'index_cycle_analytics_stage_event_hashes_on_hash_sha_256'

  def up
    remove_concurrent_index_by_name :analytics_cycle_analytics_stage_event_hashes, name: INDEX
  end

  def down
    add_concurrent_index :analytics_cycle_analytics_stage_event_hashes, :hash_sha256,
      name: INDEX,
      unique: true
  end
end
