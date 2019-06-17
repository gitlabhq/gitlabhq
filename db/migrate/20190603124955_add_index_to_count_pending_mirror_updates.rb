# frozen_string_literal: true

class AddIndexToCountPendingMirrorUpdates < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :project_mirror_data, [:last_update_at, :retry_count]
  end

  def down
    remove_concurrent_index :project_mirror_data, [:last_update_at, :retry_count]
  end
end
