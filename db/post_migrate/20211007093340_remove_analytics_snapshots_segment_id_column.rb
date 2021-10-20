# frozen_string_literal: true

class RemoveAnalyticsSnapshotsSegmentIdColumn < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    remove_column :analytics_devops_adoption_snapshots, :segment_id
  end

  def down
    add_column :analytics_devops_adoption_snapshots, :segment_id, :bigint, after: :id
    add_concurrent_foreign_key :analytics_devops_adoption_snapshots, :analytics_devops_adoption_segments,
                    column: :segment_id, name: 'fk_rails_25da9a92c0', on_delete: :cascade
    add_concurrent_index :analytics_devops_adoption_snapshots, [:segment_id, :end_time], name: :index_on_snapshots_segment_id_end_time
    add_concurrent_index :analytics_devops_adoption_snapshots, [:segment_id, :recorded_at], name: :index_on_snapshots_segment_id_recorded_at
  end
end
