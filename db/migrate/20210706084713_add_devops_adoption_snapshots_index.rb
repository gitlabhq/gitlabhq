# frozen_string_literal: true

class AddDevopsAdoptionSnapshotsIndex < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'idx_analytics_devops_adoption_snapshots_finalized'

  def up
    add_concurrent_index :analytics_devops_adoption_snapshots, [:namespace_id, :end_time], where: "recorded_at >= end_time", name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :analytics_devops_adoption_snapshots, INDEX_NAME
  end
end
