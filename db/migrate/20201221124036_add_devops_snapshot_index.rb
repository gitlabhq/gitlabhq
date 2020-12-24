# frozen_string_literal: true

class AddDevopsSnapshotIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  INDEX_NAME = 'index_on_snapshots_segment_id_end_time'

  def up
    add_concurrent_index :analytics_devops_adoption_snapshots, [:segment_id, :end_time], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :analytics_devops_adoption_snapshots, INDEX_NAME
  end
end
