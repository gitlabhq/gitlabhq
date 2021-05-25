# frozen_string_literal: true

class MakeSnapshotSegmentIdOptional < ActiveRecord::Migration[6.0]
  def up
    change_column_null(:analytics_devops_adoption_snapshots, :segment_id, true)
  end

  def down
    change_column_null(:analytics_devops_adoption_snapshots, :segment_id, false)
  end
end
